const express = require('express');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const cors = require('cors');
const bodyParser = require('body-parser');

const app = express();
const PORT = 3000;
const SECRET_KEY = 'super_secret_key_canne_proche';

app.use(cors());
app.use(bodyParser.json());

// Simulation de base de données en mémoire
const users = [
  { 
    id: 1, 
    telephone: '0123456789', 
    password: bcrypt.hashSync('password123', 10), 
    name: 'Proche Aidant' 
  }
];

const cannes = [
  { 
    id: 'canne_1', 
    nom: 'Canne de Maman', 
    telephone: '0612345678', 
    consentement: true 
  }
];

const positions = [
  { 
    canneId: 'canne_1', 
    latitude: 48.8566, 
    longitude: 2.3522, 
    horodatage: new Date().toISOString(), 
    precision: 10 
  }
];

const alertes = [
  { 
    id: 'alt_1', 
    type: 'sos', 
    horodatage: new Date().toISOString(), 
    zoneNom: 'Rue de Rivoli', 
    latitude: 48.8566, 
    longitude: 2.3522, 
    traitee: false 
  }
];

// Middleware d'authentification
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) return res.status(401).json({ error: 'Accès refusé' });

  jwt.verify(token, SECRET_KEY, (err, user) => {
    if (err) return res.status(403).json({ error: 'Token invalide' });
    req.user = user;
    next();
  });
};

// --- ROUTES AUTH ---

app.post('/api/auth/connexion', (req, res) => {
  const { telephone, motDePasse } = req.body;
  const user = users.find(u => u.telephone === telephone);

  if (user && bcrypt.compareSync(motDePasse, user.password)) {
    const token = jwt.sign({ id: user.id, telephone: user.telephone }, SECRET_KEY, { expiresIn: '24h' });
    res.json({ jeton: token, user: { id: user.id, name: user.name, telephone: user.telephone } });
  } else {
    res.status(401).json({ error: 'Identifiants incorrects' });
  }
});

app.post('/api/consentements', authenticateToken, (req, res) => {
  res.json({ success: true, message: 'Consentement enregistré' });
});

// --- ROUTES CANNES ---

app.get('/api/cannes', authenticateToken, (req, res) => {
  res.json(cannes);
});

app.get('/api/positions/:canneId', authenticateToken, (req, res) => {
  const pos = positions.filter(p => p.canneId === req.params.canneId);
  res.json(pos);
});

app.get('/api/alertes', authenticateToken, (req, res) => {
  res.json(alertes);
});

app.put('/api/alertes/:id/traiter', authenticateToken, (req, res) => {
  const alerte = alertes.find(a => a.id === req.params.id);
  if (alerte) alerte.traitee = true;
  res.json({ success: true });
});

app.put('/api/utilisateur/parametres', authenticateToken, (req, res) => {
  console.log('Mise à jour paramètres:', req.body);
  res.json({ success: true });
});

app.listen(PORT, () => {
  console.log(`🚀 Serveur Canne Proche lancé sur http://localhost:${PORT}`);
  console.log(`👤 Test Login: 0123456789 / password123`);
});
