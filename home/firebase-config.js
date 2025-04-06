<script>
const initializeFirebase = () => {
        const firebaseConfig = {
            // Clés d'API masquées et chargées de manière sécurisée
            // Ces valeurs sont normalement récupérées depuis le serveur
            apiKey: "***********************************************",
            authDomain: "walletdz-d12e0.firebaseapp.com",
            databaseURL: "https://walletdz-d12e0-default-rtdb.firebaseio.com",
            projectId: "walletdz-d12e0",
            storageBucket: "walletdz-d12e0.appspot.com",
            messagingSenderId: "***************",
            appId: "1:330293988254:web:********************************",
            measurementId: "************"
        };

        // Initialisation de Firebase
        firebase.initializeApp(firebaseConfig);
        return firebase.firestore();
    };
    </script>