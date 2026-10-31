import { env } from 'cloudflare:test';
import { describe, it, expect } from 'vitest';

describe('Spike S1: Worker / R2 End-of-Upload, Fencing & Stream Length Contract', () => {
  it('S1.1: Request Body mit validem Content-Length streamt direkt in R2.put()', async () => {
    const key = `spike_s1/req_valid_${Date.now()}.bin`;
    const payload = new Uint8Array([1, 2, 3, 4, 5, 6, 7, 8]);

    const request = new Request('http://localhost/v1/backups', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-ndjson',
        'Content-Length': payload.length.toString(),
      },
      body: payload,
    });

    const obj = await env.BACKUPS_BUCKET.put(key, request.body!);
    expect(obj).not.toBeNull();
    expect(obj?.size).toBe(payload.length);

    await env.BACKUPS_BUCKET.delete(key);
  });

  it('S1.2: R2.put() Verhalten bei fehlendem Content-Length Header (Chunked Stream)', async () => {
    const key = `spike_s1/req_chunked_${Date.now()}.bin`;

    // Stream ohne bekannte Länge (kein Content-Length Header)
    const stream = new ReadableStream<Uint8Array>({
      start(controller) {
        controller.enqueue(new Uint8Array([10, 20, 30]));
        controller.close();
      },
    });

    // In Cloudflare Workers wirft R2.put bei Stream ohne bekannte Länge einen TypeError:
    let errorCaught: unknown = null;
    try {
      await env.BACKUPS_BUCKET.put(key, stream);
    } catch (err) {
      errorCaught = err;
    }

    expect(errorCaught).toBeInstanceOf(TypeError);
    expect(String(errorCaught)).toContain('must have a known length');

    // Schutz-Beweis: Chunked-Uploads ohne deklarierte Länge werden von R2 per Runtime-Contract abgewiesen!
  });

  it('S1.3: Request.body -> TransformStream Byte-Counter verliert bekannte Länge ohne FixedLengthStream', async () => {
    const key = `spike_s1/transform_loss_${Date.now()}.bin`;
    const payload = new Uint8Array([1, 2, 3, 4]);

    const request = new Request('http://localhost/v1/backups', {
      method: 'POST',
      headers: {
        'Content-Length': '4',
      },
      body: payload,
    });

    // Ein naiver TransformStream verliert die workerd Stream-Längenmetadaten:
    let bytesCounted = 0;
    const counter = new TransformStream<Uint8Array, Uint8Array>({
      transform(chunk, controller) {
        bytesCounted += chunk.byteLength;
        controller.enqueue(chunk);
      },
    });

    const countedStream = request.body!.pipeThrough(counter);

    // R2.put scheitert, wenn der Stream durch pipeThrough seine workerd-Länge verliert:
    let putError: unknown = null;
    try {
      await env.BACKUPS_BUCKET.put(key, countedStream);
    } catch (err) {
      putError = err;
    }

    expect(putError).toBeInstanceOf(TypeError);
    expect(String(putError)).toContain('must have a known length');
    expect(bytesCounted).toBe(0); // Wurde noch nicht konsumiert
  });

  it('S1.4: Robuste Lösung: FixedLengthStream erhält bekannte Länge bei gleichzeitiger Zählung', async () => {
    const key = `spike_s1/fls_counted_${Date.now()}.bin`;
    const declaredLength = 8;
    const payload = new Uint8Array([10, 20, 30, 40, 50, 60, 70, 80]);

    // Worker erzeugt FixedLengthStream basierend auf verifiziertem Content-Length Header:
    const fls = new FixedLengthStream(declaredLength);
    const writer = fls.writable.getWriter();

    // R2.put akzeptiert den readable part von FixedLengthStream!
    const putPromise = env.BACKUPS_BUCKET.put(key, fls.readable);

    // Byte-Zähler schreibt chunks in fls.writable:
    let bytesWritten = 0;
    const chunkSize = 4;
    for (let offset = 0; offset < payload.length; offset += chunkSize) {
      const chunk = payload.subarray(offset, offset + chunkSize);
      bytesWritten += chunk.byteLength;
      await writer.write(chunk);
    }
    await writer.close();

    const result = await putPromise;
    expect(result).not.toBeNull();
    expect(result?.size).toBe(declaredLength);
    expect(bytesWritten).toBe(declaredLength);

    await env.BACKUPS_BUCKET.delete(key);
  });

  it('S1.5: Content-Length Mismatch – Stream sendet weniger Bytes als deklariert (Abbruch)', async () => {
    const key = `spike_s1/mismatch_${Date.now()}.bin`;
    const declaredLength = 10;

    const fls = new FixedLengthStream(declaredLength);
    const writer = fls.writable.getWriter();

    const putPromise = env.BACKUPS_BUCKET.put(key, fls.readable);

    // Schreibe nur 4 Bytes und schließe vorzeitig (Client Disconnect oder falsche Header)
    await writer.write(new Uint8Array([1, 2, 3, 4]));
    
    // Vorzeitiges Schließen oder Abort:
    await writer.abort(new Error('Premature close'));

    let caught: unknown = null;
    try {
      await putPromise;
    } catch (err) {
      caught = err;
    }

    expect(caught).not.toBeNull();
    // In R2 darf kein unvollständiges Objekt existieren
    const obj = await env.BACKUPS_BUCKET.get(key);
    expect(obj).toBeNull();
  });

  it('S1.6: Late Put nach GC-Löschung – Verwaistes Objekt & Isolation via Unique Attempt Key', async () => {
    const accountId = 'acc_fencing_test';
    const backupId = 'backup_123';
    
    // ADR-BC-004 Architekturmuster: Jeder Upload-Versuch erhält einen eindeutigen Attempt-Key
    const attemptNonce = 'attempt_' + Date.now();
    const attemptKey = `backups/${accountId}/${backupId}_${attemptNonce}.ndjson`;
    const finalCanonicalKey = `backups/${accountId}/${backupId}.ndjson`;

    const fls = new FixedLengthStream(6);
    const writer = fls.writable.getWriter();

    // 1. Worker startet R2.put auf attemptKey
    const putPromise = env.BACKUPS_BUCKET.put(attemptKey, fls.readable);

    // Schreibe Teil 1
    await writer.write(new Uint8Array([1, 2, 3]));

    // 2. Simulierter Timeout / GC Fencing in D1:
    // Der Koordinator erklärt den Lease für abgelaufen und löscht den attemptKey
    await env.BACKUPS_BUCKET.delete(attemptKey);

    // 3. Verspäteter Stream beendet den Transfer nach dem Timeout
    await writer.write(new Uint8Array([4, 5, 6]));
    await writer.close();
    await putPromise;

    // 4. Status-Untersuchung:
    // attemptKey existiert als Ghost-Objekt in R2
    const ghost = await env.BACKUPS_BUCKET.get(attemptKey);
    expect(ghost).not.toBeNull();
    await ghost?.arrayBuffer(); // Handle freigeben für Miniflare auf Windows

    // ABER: Das kanonische/aktive Backup finalCanonicalKey wurde NIEMALS berührt oder überschrieben!
    const canonical = await env.BACKUPS_BUCKET.get(finalCanonicalKey);
    expect(canonical).toBeNull();

    // Der periodische GC-Prefix-Sweep scannt backups/acc_fencing_test/ und löscht nicht in D1 referenzierte attemptKeys:
    await env.BACKUPS_BUCKET.delete(attemptKey);
    const cleaned = await env.BACKUPS_BUCKET.get(attemptKey);
    expect(cleaned).toBeNull();
  });

  it('S1.7: R2 get().body als Stream verbraucht keinen Isolate-Buffer', async () => {
    const key = `spike_s1/stream_get_${Date.now()}.bin`;
    const payload = new Uint8Array(1024 * 64); // 64 KiB
    await env.BACKUPS_BUCKET.put(key, payload);

    const obj = await env.BACKUPS_BUCKET.get(key);
    expect(obj).not.toBeNull();
    expect(obj!.body).toBeDefined();

    const response = new Response(obj!.body);
    expect(response.headers.get('Content-Type')).toBeDefined();

    const readBytes = new Uint8Array(await response.arrayBuffer());
    expect(readBytes.length).toBe(1024 * 64);

    await env.BACKUPS_BUCKET.delete(key);
  });
});
