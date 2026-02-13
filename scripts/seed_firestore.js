const path = require('path');
const admin = require('firebase-admin');

const serviceAccountPath = path.join(__dirname, 'serviceAccountKey.json');
const serviceAccount = require(serviceAccountPath);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: serviceAccount.project_id,
});

const db = admin.firestore();
db.settings({ databaseId: 'default' });
const { Timestamp } = admin.firestore;

async function seed() {
  const now = Timestamp.now();

  // Users
  const users = [
    {
      uid: 'uid_admin',
      data: {
        email: 'admin@test.com',
        fullName: 'DUPONT JEAN',
        role: 'admin',
        createdAt: now,
        updatedAt: now,
      },
    },
    {
      uid: 'uid_chercheur_1',
      data: {
        email: 'chercheur1@test.com',
        fullName: 'BEN SALEM AMINE',
        role: 'chercheur',
        createdAt: now,
        updatedAt: now,
      },
    },
    {
      uid: 'uid_chercheur_2',
      data: {
        email: 'chercheur2@test.com',
        fullName: 'KHALIL AMINA',
        role: 'chercheur',
        createdAt: now,
        updatedAt: now,
      },
    },
  ];

  for (const u of users) {
    await db.collection('users').doc(u.uid).set(u.data, { merge: true });
  }

  // Surveys
  const surveys = [
    {
      id: 'survey_001',
      data: {
        title: 'Enquête Golfe de Tunis',
        type: 'enquete',
        location: 'Golfe de Tunis',
        zone: 'Zone A',
        dateEnquete: Timestamp.fromDate(new Date('2026-02-08T00:00:00Z')),
        status: 'en_cours',
        createdBy: 'uid_admin',
        assignedTo: ['uid_chercheur_1', 'uid_chercheur_2'],
        createdAt: now,
        updatedAt: now,
      },
    },
    {
      id: 'survey_002',
      data: {
        title: 'Données laboratoire Bizerte',
        type: 'lab',
        location: 'Lac de Bizerte',
        zone: 'Zone B',
        dateEnquete: Timestamp.fromDate(new Date('2026-02-07T00:00:00Z')),
        status: 'brouillon',
        createdBy: 'uid_admin',
        assignedTo: ['uid_chercheur_1'],
        createdAt: now,
        updatedAt: now,
      },
    },
  ];

  for (const s of surveys) {
    await db.collection('surveys').doc(s.id).set(s.data, { merge: true });
  }

  // Sub-collections for survey_001
  const surveyRef = db.collection('surveys').doc('survey_001');

  await surveyRef.collection('responses').doc('response_001').set(
    {
      surveyId: 'survey_001',
      userId: 'uid_chercheur_1',
      role: 'chercheur',
      status: 'soumise',
      answers: {
        temperature: 22.5,
        salinite: 35,
        observations: 'Présence de crabes bleus',
      },
      createdAt: now,
      updatedAt: now,
      submittedAt: now,
    },
    { merge: true }
  );

  await surveyRef.collection('lab_data').doc('lab_001').set(
    {
      surveyId: 'survey_001',
      userId: 'uid_chercheur_1',
      data: {
        ph: 7.2,
        metaux_lourds: 'faible',
      },
      createdAt: now,
      updatedAt: now,
    },
    { merge: true }
  );

  await surveyRef.collection('lek_responses').doc('lek_001').set(
    {
      surveyId: 'survey_001',
      userId: 'uid_chercheur_2',
      answers: {
        q1: 'faible',
        q2: 3,
      },
      createdAt: now,
      updatedAt: now,
    },
    { merge: true }
  );

  console.log('Seed completed.');
}

seed()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });
