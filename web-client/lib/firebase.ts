import { initializeApp, getApps } from 'firebase/app';
import { getAuth } from 'firebase/auth';

const firebaseConfig = {
  apiKey: "AIzaSyCNktQV2L5nPfB5VRKLPbgsBaZ_TFp_F7M",
  authDomain: "citk-connect-project.firebaseapp.com",
  projectId: "citk-connect-project",
  storageBucket: "citk-connect-project.firebasestorage.app",
  messagingSenderId: "418075503046",
  appId: "1:418075503046:web:84e665b6ea349ba8d32ac7",
  measurementId: "G-1Q57QB41WJ"
};

let app;
if (!getApps().length) {
  app = initializeApp(firebaseConfig);
} 

const auth = getAuth(app);

export { auth, app };
