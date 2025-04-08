// Initialiser Supabase
const { createClient } = supabase;
const supabaseUrl = 'https://zjbnzghyhdhlivpokstz.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpqYm56Z2h5aGRobGl2cG9rc3R6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzg2ODA1MjcsImV4cCI6MjA1NDI1NjUyN30.99PBeSXyoFJQMFopizHfLDlqLrMunSBLlBfTGcLIpv8';
const supabase = createClient(supabaseUrl, supabaseKey);

async function ajouterSignalement() {
    const numero = document.getElementById('numero').value.trim();
    const motif = document.getElementById('motif').value.trim();
    const signalePar = 'Utilisateur'; // Vous pouvez personnaliser cela selon vos besoins
    const description = ''; // Optionnel, peut être rempli par l'utilisateur

    const normalizedNumero = normalizeAndValidateAlgerianPhone(numero);
    if (!normalizedNumero) {
        alert("Le numéro de téléphone est invalide.");
        return;
    }

    const signalement = {
        numero: normalizedNumero,
        description: description,
        signalePar: signalePar,
        motif: motif,
        gravite: 1, // Vous pouvez ajuster cela selon vos besoins
        date: new Date().toISOString(),
    };

    const { error } = await supabase
        .from('signalements')
        .insert([signalement]);

    if (error) {
        console.error('Erreur lors de l\'ajout du signalement:', error);
        showSnackbar('Erreur lors de l\'ajout du signalement.', 'error');
        return;
    }

    document.getElementById('numero').value = '';
    document.getElementById('motif').value = '';

    // Afficher un message de succès
    showSnackbar(`Le numéro 0${normalizedNumero} a bien été signalé`, 'success');

    // Rechercher les signalements après l'ajout pour mettre à jour l'affichage
    rechercherSignalement();
}

async function rechercherSignalement() {
    const numero = document.getElementById('numero').value.trim();
    const normalizedNumero = normalizeAndValidateAlgerianPhone(numero);
    if (!normalizedNumero) {
        alert("Le numéro de téléphone est invalide.");
        return;
    }

    const { data, error } = await supabase
        .from('signalements')
        .select('*')
        .eq('numero', normalizedNumero);

    if (error) {
        console.error('Erreur lors de la récupération des signalements:', error);
        alert('Erreur lors de la récupération des signalements.');
        return;
    }

    afficherResultat(normalizedNumero, data);
}

function afficherResultat(numero, signalements = []) {
    const resultatDiv = document.getElementById('resultat');
    const nbSignalements = signalements.length;
    resultatDiv.innerHTML = `
        <p>${nbSignalements === 0 ?
            `Ce numéro de téléphone 0${numero} n'a jamais été signalé` :
            `Ce numéro de téléphone 0${numero} a été signalé ${nbSignalements} fois`}</p>
        <div id="dangerBar"></div>
    `;
    animerDangerBar(nbSignalements);
}

function normalizeAndValidateAlgerianPhone(numero) {
    let num = numero.replace(/\s+/g, '');
    if (num.startsWith('213')) num = num.substring(3);
    if (num.startsWith('+213')) num = num.substring(4);
    if (num.startsWith('00213')) num = num.substring(5);
    if (num.startsWith('0')) num = num.substring(1);
    return /^[5-7][0-9]{8}$/.test(num) ? num : null;
}

function animerDangerBar(degree) {
    const dangerBar = document.getElementById('dangerBar');
    dangerBar.style.width = `${degree * 20}%`;
    dangerBar.style.backgroundColor = getColorForSignalements(degree);
    dangerBar.innerText = getTextForSignalements(degree);
}

function getColorForSignalements(signalements) {
    if (signalements === 0) return 'green';
    if (signalements === 1) return 'lightgreen';
    if (signalements === 2) return 'yellow';
    if (signalements === 3 || signalements === 4) return 'orange';
    if (signalements >= 5) return 'red';
    return 'grey';
}

function getTextForSignalements(signalements) {
    if (signalements === 0) return 'Ce numéro n\'a jamais été signalé.';
    if (signalements === 1) return 'Ce numéro présente un risque modéré.';
    if (signalements === 2) return 'Ce numéro présente un risque moyen.';
    if (signalements === 3 || signalements === 4) return 'Ce numéro présente un risque élevé.';
    if (signalements >= 5) return 'Ce numéro présente un risque très élevé.';
    return 'État de signalement inconnu.';
}

function showSnackbar(message, type = 'success') {
    const snackbar = document.getElementById('snackbar');
    snackbar.textContent = message;
    snackbar.className = 'show';
    snackbar.style.backgroundColor = type === 'success' ? 'green' : 'red';
    setTimeout(() => {
        snackbar.className = snackbar.className.replace('show', '');
    }, 3000);
}
