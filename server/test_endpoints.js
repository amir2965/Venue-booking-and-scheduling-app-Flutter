const axios = require('axios');

const BASE_URL = 'http://localhost:5000/api';

async function testEndpoints() {
  const endpoints = [
    { method: 'GET', path: '/health' },
    { method: 'GET', path: '/profiles' },
    { method: 'POST', path: '/test/create-mock-profile' },
  ];

  for (const endpoint of endpoints) {
    try {
      const response = await axios({
        method: endpoint.method,
        url: BASE_URL + endpoint.path
      });
      console.log(`✅ ${endpoint.method} ${endpoint.path} - Status: ${response.status}`);
    } catch (error) {
      console.log(`❌ ${endpoint.method} ${endpoint.path} - Error: ${error.response?.status || error.message}`);
    }
  }
}

testEndpoints();
