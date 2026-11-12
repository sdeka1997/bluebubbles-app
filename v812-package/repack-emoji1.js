// Sequoia test build "emoji1": production v8.12.19 ASAR + main.js from /tmp/wseq-server
// (sequoia/integration b37c21d7) + node_modules/@noble/ciphers 1.3.0 (new runtime dependency).
const asar = require("@electron/asar");
const crypto = require("crypto");
const fs = require("fs");
const path = require("path");

const home = process.env.HOME;
const root = path.join(home, "BlueBubbles-v812-Package");
const sourceRoot = "/tmp/wseq2-server";
const nobleSource = "/tmp/noble-scratch/node_modules/@noble/ciphers";
const base = path.join(root, "app.custom.v8.12.19.asar");
const extractDir = path.join(root, "extracted-emoji1");
const output = path.join(root, "app.custom.emoji1.asar");

const sha256Buffer = data => crypto.createHash("sha256").update(data).digest("hex");
const sha256File = file => sha256Buffer(fs.readFileSync(file));
const unpackedFiles = archive => asar.listPackage(archive, { isPack: true })
    .filter(entry => entry.startsWith("unpack : "))
    .map(entry => entry.slice("unpack : ".length).replace(/^\//, ""))
    .filter(entry => !asar.statFile(archive, entry).files)
    .sort();
const listFiles = dir => fs.readdirSync(dir, { withFileTypes: true }).flatMap(entry => {
    const full = path.join(dir, entry.name);
    return entry.isDirectory() ? listFiles(full).map(f => path.join(entry.name, f)) : [entry.name];
}).sort();

(async () => {
    if (sha256File(base) !== "b462b06d237a306f25194a4b22acd91b71296bfea3e39d5fa830cb91aa03913a") {
        throw new Error("v8.12.19 base ASAR hash mismatch");
    }
    const expectedUnpacked = unpackedFiles(base);
    if (expectedUnpacked.length !== 28) throw new Error(`expected 28 unpacked files, got ${expectedUnpacked.length}`);

    const noblePkg = JSON.parse(fs.readFileSync(path.join(nobleSource, "package.json"), "utf8"));
    if (noblePkg.name !== "@noble/ciphers" || noblePkg.version !== "1.3.0") {
        throw new Error(`unexpected noble package ${noblePkg.name}@${noblePkg.version}`);
    }
    if (noblePkg.dependencies && Object.keys(noblePkg.dependencies).length) {
        throw new Error("@noble/ciphers has runtime dependencies; they would need adding too");
    }

    fs.rmSync(extractDir, { recursive: true, force: true });
    fs.rmSync(output, { force: true });
    fs.rmSync(`${output}.unpacked`, { recursive: true, force: true });
    asar.extractAll(base, extractDir);

    // better-sqlite3 is how stock reads chat.db; it must already be in the base. Its .node is
    // PACKED (not in .unpacked) in the official and v8.12.19 ASARs; Electron dlopens it from asar.
    const bsqlPkg = JSON.parse(fs.readFileSync(path.join(extractDir, "node_modules/better-sqlite3/package.json"), "utf8"));
    const bsqlNative = listFiles(path.join(extractDir, "node_modules/better-sqlite3")).filter(f => f.endsWith(".node"));
    if (!bsqlNative.length) throw new Error("better-sqlite3 has no .node binary in the base");

    const nobleDest = path.join(extractDir, "node_modules/@noble/ciphers");
    if (fs.existsSync(nobleDest)) throw new Error("base already contains @noble/ciphers");
    fs.cpSync(nobleSource, nobleDest, { recursive: true });

    for (const name of ["main.js", "main.js.map"]) {
        fs.copyFileSync(path.join(sourceRoot, "packages/server/dist", name), path.join(extractDir, "dist", name));
    }

    const unpackPattern = path.join(extractDir, `{${expectedUnpacked.join(",")}}`);
    await asar.createPackageWithOptions(extractDir, output, { unpack: unpackPattern });

    const actualUnpacked = unpackedFiles(output);
    if (JSON.stringify(actualUnpacked) !== JSON.stringify(expectedUnpacked)) {
        throw new Error("emoji1 unpacked-file set differs from v8.12.19");
    }
    for (const relative of actualUnpacked) {
        const stat = asar.statFile(output, relative);
        const bytes = fs.readFileSync(path.join(`${output}.unpacked`, relative));
        if (stat.size !== bytes.length) throw new Error(`size mismatch: ${relative}`);
        if (!stat.integrity || stat.integrity.hash !== sha256Buffer(bytes)) {
            throw new Error(`integrity mismatch: ${relative}`);
        }
    }

    // Every noble file landed packed and byte-identical.
    const nobleFiles = listFiles(nobleSource);
    for (const relative of nobleFiles) {
        const inAsar = asar.extractFile(output, path.join("node_modules/@noble/ciphers", relative));
        if (sha256Buffer(inAsar) !== sha256File(path.join(nobleSource, relative))) {
            throw new Error(`noble file mismatch: ${relative}`);
        }
    }

    // Every file of the base is still present with the same bytes, except the swapped main.js/.map.
    const baseFiles = asar.listPackage(base).map(e => e.replace(/^\//, "")).filter(e => !asar.statFile(base, e).files);
    const outFiles = new Set(asar.listPackage(output).map(e => e.replace(/^\//, "")));
    let unchanged = 0;
    for (const relative of baseFiles) {
        if (!outFiles.has(relative)) throw new Error(`file dropped: ${relative}`);
        if (relative === "dist/main.js" || relative === "dist/main.js.map") continue;
        const a = asar.statFile(base, relative);
        const b = asar.statFile(output, relative);
        if (a.size !== b.size || (a.integrity && b.integrity && a.integrity.hash !== b.integrity.hash)) {
            throw new Error(`file changed: ${relative}`);
        }
        unchanged++;
    }

    const main = asar.extractFile(output, "dist/main.js").toString("utf8");
    const markers = [
        // v8.12.19 production markers
        "swapnav/readsync-findmy-v812",
        "CUSTOM_BUILD_UPDATE_DISABLED",
        "BeaconStoreKey",
        "chat-deleted",
        "chat-state/snapshot",
        "filename*=UTF-8",
        "isFilteredAsSpam",
        "message-deleted",
        "message-restored",
        "chat_recoverable_message_join",
        "SMSCategory",
        "newer_m.date > m.date",
        "favorite_order",
        "Skipping FCM notification: the message is too large",
        "findmy-geocoder.js",
        "deletedMessageGuids",
        "m.date > COALESCE(c.last_read_message_timestamp, 0)",
        "hasAnyLocation",
        "OR m.date_read > 0",
        "AddExternalIdToContacts1750299580000",
        "name of processes",
        // emoji1 additions
        "serviceName",                                          // feat/rcs-service
        "isGreaterThanOrEqualTo(\"14.4\")",                      // isMinSonoma14_4 (name minified)
        "LocalStorage.db",                                      // feat/sequoia-findmy
        "findmylocateagent",
        "chacha20poly1305",
        "require(\"@noble/ciphers/chacha\")",
        "secureLocations",
        "reactionEmoji",
        "associated_message_emoji"
    ];
    for (const marker of markers) {
        if (!main.includes(marker)) throw new Error(`missing marker: ${marker}`);
    }
    for (const gone of ["delete/recoverable", "recoverable-delete-chat"]) {
        if (main.includes(gone)) throw new Error(`withdrawn code still present: ${gone}`);
    }
    if (!/function [\w$]+\(t,e\)\{return t===[\w$]+\?"high":e\}/.test(main)) {
        throw new Error("missing marker: read-status high priority");
    }

    const rawHeader = asar.getRawHeader(output);
    console.log(JSON.stringify({
        base_sha256: sha256File(base),
        output_sha256: sha256File(output),
        electron_asar_integrity: sha256Buffer(Buffer.from(rawHeader.headerString)),
        main_sha256: sha256Buffer(asar.extractFile(output, "dist/main.js")),
        main_map_sha256: sha256Buffer(asar.extractFile(output, "dist/main.js.map")),
        unpacked_files: actualUnpacked.length,
        base_files_unchanged: unchanged,
        noble_files_added: nobleFiles.length,
        better_sqlite3: { version: bsqlPkg.version, native_in_asar: bsqlNative },
        markers_verified: markers.length + 3
    }, null, 2));
    fs.rmSync(extractDir, { recursive: true, force: true });
})().catch(error => {
    console.error(error && error.stack ? error.stack : String(error));
    process.exit(1);
});
