const admin = require("firebase-admin");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");

const sa = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(sa),
  projectId: sa.project_id,
});

// IMPORTANT: ton databaseId est "default" (et pas "(default)")
const db = getFirestore(admin.app(), "default");

function normalizeErrorCode(err) {
  const fromCode = String(err && err.code ? err.code : "").trim();
  const fromMessage = String(err && err.message ? err.message : "");
  const combined = `${fromCode} ${fromMessage}`.toUpperCase();

  if (combined.includes("NOT_FOUND")) return "NOT_FOUND";
  if (combined.includes("PERMISSION_DENIED")) return "PERMISSION_DENIED";
  if (combined.includes("UNAUTHENTICATED")) return "UNAUTHENTICATED";
  if (combined.includes("UNAVAILABLE")) return "UNAVAILABLE";
  if (fromCode) return fromCode.toUpperCase();
  return "UNKNOWN";
}

function logDiagnostics() {
  console.log("--- Firestore diagnostics ---");
  console.log(`serviceAccount.project_id=${sa.project_id || ""}`);
  console.log(
    `admin.app().options.projectId=${admin.app().options.projectId || ""}`
  );
  console.log(
    `FIRESTORE_EMULATOR_HOST=${process.env.FIRESTORE_EMULATOR_HOST || ""}`
  );
  console.log(
    `GOOGLE_CLOUD_PROJECT=${process.env.GOOGLE_CLOUD_PROJECT || ""}`
  );
  console.log(`GCLOUD_PROJECT=${process.env.GCLOUD_PROJECT || ""}`);
  console.log("-----------------------------");
}

function assertNoEmulatorTarget() {
  if (process.env.FIRESTORE_EMULATOR_HOST) {
    console.error(
      "⚠️ FIRESTORE_EMULATOR_HOST est défini => le script vise l'émulateur. Supprime cette variable si tu veux écrire sur Firebase Cloud."
    );
    process.exit(1);
  }
}

async function testFirestoreConnectivity() {
  let pingRef;
  try {
    pingRef = await db.collection("debug_tests").add({
      ping: "ok",
      ts: FieldValue.serverTimestamp(),
    });
    const pingSnap = await pingRef.get();
    if (!pingSnap.exists) {
      throw new Error(
        "PING_READ_FAILED: document debug_tests ecrit mais non relu."
      );
    }
    console.log(`✅ OK test connectivite Firestore: ${pingRef.id}`);
  } catch (err) {
    const code = normalizeErrorCode(err);
    const message = err && err.message ? err.message : String(err);
    console.error(`❌ Firestore connectivite code=${code}`);
    console.error(`❌ Firestore connectivite message=${message}`);
    console.error(
      "Suggestion: Active Cloud Firestore API dans Google Cloud Console"
    );
    console.error("Suggestion: Verifie que la base (default) existe");
    process.exit(1);
  }
}

async function seed() {
  const terrainPayload = {
    ownerId: "UID_CHERCHEUR_001",
    ownerName: "BEN SALEM AMINE",
    role: "chercheur",
    roleCreateur: "chercheur",
    type: "terrain",
    title: "Enquête Terrain - Golfe de Tunis",
    status: "brouillon",
    stepCompleted: 3,
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
    lastEditedAt: FieldValue.serverTimestamp(),
    submittedAt: null,
    data: {
      gen_qcFlag: 0,
      gen_idEnqueteur: "AMINE BEN SALEM",
      gen_idObservation: "OBS-2026-0001",
      gen_date: "19-02-2026",
      gen_heure: "10:45",
      gen_pays: "Tunisie",
      gen_region: "Nord",
      gen_portPeche: "La Goulette",
      gen_zone: "Zone A",
      gen_longitude: "10.3021",
      gen_latitude: "36.8188",
      suivi_typeObservation: "au port",
      suivi_typeEnginCode: "Nasses (casiers) : NC",
      suivi_typeEnginAutre: "",
      suivi_typeEngin: "Nasse",
      suivi_nbPieces: "10",
      suivi_idNavire: "NAV-23 / El Bahri",
      suivi_idNasse: "4",
      suivi_debut: "06:30",
      suivi_fin: "09:20",
      suivi_nc_diametre: "45",
      suivi_nc_hauteur: "25",
      suivi_nc_ouverture: "12",
      suivi_nc_maille: "25",
      suivi_nc_nbre: "10",
      suivi_nc_typeNasses: "casiers ronds",
      cap_nomCommun: "Crabe bleu",
      cap_espece: "Portunus segnis",
      cap_abondance: "12",
      cap_poidsTotal: "3500",
      env_substrat: "vase",
      env_profondeur: "Entre 1 et 3 m",
      env_temperature: "22.4",
      env_oxygene: "7.3",
      env_salinite: "35",
      rem_pecheurReticent: false,
      rem_infoPartielle: false,
      rem_gpsEstime: true,
      rem_text: "GPS estimé (pas mesuré). Bonne disponibilité du pêcheur.",
    },
  };

  const labPayload = {
    ownerId: "UID_CHERCHEUR_001",
    ownerName: "BEN SALEM AMINE",
    role: "chercheur",
    roleCreateur: "chercheur",
    type: "lab",
    title: "Données Laboratoire - OBS-2026-0001",
    status: "brouillon",
    stepCompleted: 2,
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
    lastEditedAt: FieldValue.serverTimestamp(),
    submittedAt: null,
    data: {
      idObservation: "OBS-2026-0001",
      dateReception: "19-02-2026",
      idLaboratoire: "LAB-01",
      idAnalyste: "AN-07",
      dateAnalyse: "19-02-2026",
      qcFlag: "0",
      espece: "Portunus segnis",
      idIndividu: "IND-004",
      sexe: "M",
      stade: "adulte",
      maturite: "Mature",
      cw: "92.5",
      cl: "55.2",
      epaisseurC: "11.3",
      poidsTotal: "325.6",
      poidsEviscere: "280.4",
      appendicesGauche: "8",
      appendicesDroit: "8",
      pincesManquantes: "non",
      couleurOeufs: "ST1",
      poidsGonades: "8.2",
      poidsOeufs: "0",
      poidsEstomac: "2.1",
      indiceGonado: "2.5",
      poidsSpermatheque: "0",
      stadeMue: "intermue",
      tauxProteines: "18.2",
      tauxLipides: "1.6",
      tauxProteines2: "4.1",
      humidite: "75.3",
      cendres: "2.8",
      epibiontesOuiNon: "non",
      epibiontesDescription: "",
      epibiontesType: "",
      epibiontesEspeces: "",
      remarques: "Échantillon correct. Valeurs cohérentes.",
    },
  };

  const terrainRef = db.collection("terrain_forms").doc();
  const labRef = db.collection("lab_forms").doc();

  await terrainRef.set(terrainPayload);
  console.log(`✅ OK terrain_forms créé: ${terrainRef.id}`);

  await labRef.set(labPayload);
  console.log(`✅ OK lab_forms créé: ${labRef.id}`);

  const [terrainSnap, labSnap] = await Promise.all([
    terrainRef.get(),
    labRef.get(),
  ]);

  console.log(
    `✅ OK vérification lecture: terrain=${terrainSnap.exists} lab=${labSnap.exists}`
  );
}

async function main() {
  logDiagnostics();
  assertNoEmulatorTarget();
  await testFirestoreConnectivity();
  await seed();
}

main()
  .then(() => {
    process.exitCode = 0;
  })
  .catch((err) => {
    const code = normalizeErrorCode(err);
    const message = err && err.message ? err.message : String(err);

    console.error(`❌ Firestore seed error code=${code}`);
    console.error(`❌ Firestore seed error message=${message}`);

    if (code === "NOT_FOUND") {
      console.error("Crée Firestore (default) dans Firebase Console");
    }

    process.exitCode = 1;
  });
