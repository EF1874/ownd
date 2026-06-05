require('dotenv').config({ path: '.env.development' });

const baseUrl = 'http://localhost:3000/api/v1';

async function main() {
  try {
    // 1. Log in
    const loginRes = await fetch(`${baseUrl}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: '284264018@qq.com',
        password: '123456'
      })
    });
    
    const loginData = await loginRes.json();
    const token = loginData.data?.access_token;
    
    // 2. Fetch items
    const itemsRes = await fetch(`${baseUrl}/items`, {
      headers: { 
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    });
    
    const itemsData = await itemsRes.json();
    console.log('Items response:', JSON.stringify(itemsData, null, 2));
  } catch (error) {
    console.error('Error fetching items:', error.message);
  }
}

main();
