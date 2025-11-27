const express = require('express');
const router = express.Router();
const usernameController = require('../controllers/usernameController');

// Route for checking username availability
router.get('/check', usernameController.checkUsernameAvailability);

// Route for reserving a username
router.post('/reserve', usernameController.reserveUsername);

// Route for updating a username
router.put('/update', usernameController.updateUsername);

module.exports = router;
