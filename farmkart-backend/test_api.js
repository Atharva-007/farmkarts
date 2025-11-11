// Test script for Product Management API
const axios = require('axios');

const BASE_URL = 'http://localhost:3001/api';
const AUTH_TOKEN = 'test-token-123'; // Mock token for testing

// Test configuration
const testData = {
  product: {
    name: 'Fresh Organic Tomatoes',
    description: 'High-quality organic tomatoes grown without pesticides. Perfect for salads and cooking.',
    category: 'Vegetables',
    price: 45.50,
    unit: 'kg',
    quantity: 25,
    location: 'Punjab, India',
    tags: ['organic', 'fresh', 'tomatoes', 'vegetables'],
    isOrganic: true,
    harvestDate: '2024-11-01',
    certificationDetails: 'Organic India Certified'
  }
};

// Helper function for API requests with auth
const apiRequest = (method, url, data = null) => {
  return axios({
    method,
    url: `${BASE_URL}${url}`,
    data,
    headers: {
      'Authorization': `Bearer ${AUTH_TOKEN}`,
      'Content-Type': 'application/json'
    }
  });
};

// Test functions
async function testHealthCheck() {
  console.log('\n🔍 Testing Health Check...');
  try {
    const response = await axios.get(`${BASE_URL}/health`);
    console.log('✅ Health check passed:', response.data);
    return true;
  } catch (error) {
    console.error('❌ Health check failed:', error.message);
    return false;
  }
}

async function testCreateProduct() {
  console.log('\n📦 Testing Product Creation...');
  try {
    const response = await apiRequest('POST', '/products', testData.product);
    console.log('✅ Product created successfully:', {
      id: response.data.data.id,
      name: response.data.data.name,
      price: response.data.data.price
    });
    return response.data.data.id;
  } catch (error) {
    console.error('❌ Product creation failed:', error.response?.data || error.message);
    return null;
  }
}

async function testGetProducts() {
  console.log('\n📋 Testing Get Products...');
  try {
    const response = await axios.get(`${BASE_URL}/products`);
    console.log(`✅ Retrieved ${response.data.data.length} products`);
    if (response.data.data.length > 0) {
      const product = response.data.data[0];
      console.log('   Sample product:', {
        id: product.id,
        name: product.name,
        price: product.price,
        category: product.category
      });
    }
    return response.data.data;
  } catch (error) {
    console.error('❌ Get products failed:', error.response?.data || error.message);
    return [];
  }
}

async function testGetProductById(productId) {
  console.log(`\n🔍 Testing Get Product by ID: ${productId}...`);
  try {
    const response = await axios.get(`${BASE_URL}/products/${productId}`);
    console.log('✅ Product details retrieved:', {
      id: response.data.data.id,
      name: response.data.data.name,
      viewCount: response.data.data.viewCount
    });
    return response.data.data;
  } catch (error) {
    console.error('❌ Get product by ID failed:', error.response?.data || error.message);
    return null;
  }
}

async function testGetSellingHistory() {
  console.log('\n📊 Testing Selling History...');
  try {
    const response = await axios.get(`${BASE_URL}/users/test-user-123/selling-history`, {
      headers: {
        'Authorization': `Bearer ${AUTH_TOKEN}`
      }
    });
    console.log(`✅ Retrieved selling history with ${response.data.data.length} items`);
    console.log('   Summary:', response.data.summary);
    return response.data.data;
  } catch (error) {
    console.error('❌ Get selling history failed:', error.response?.data || error.message);
    return [];
  }
}

async function testProductFiltering() {
  console.log('\n🔍 Testing Product Filtering...');
  try {
    // Test category filter
    const vegResponse = await axios.get(`${BASE_URL}/products?category=Vegetables`);
    console.log(`✅ Vegetables category: ${vegResponse.data.data.length} products`);
    
    // Test search
    const searchResponse = await axios.get(`${BASE_URL}/products?search=tomato`);
    console.log(`✅ Search 'tomato': ${searchResponse.data.data.length} products`);
    
    // Test organic filter
    const organicResponse = await axios.get(`${BASE_URL}/products?isOrganic=true`);
    console.log(`✅ Organic products: ${organicResponse.data.data.length} products`);
    
    return true;
  } catch (error) {
    console.error('❌ Product filtering failed:', error.response?.data || error.message);
    return false;
  }
}

// Main test runner
async function runTests() {
  console.log('🚀 Starting FarmKart Product Management API Tests');
  console.log('================================================');
  
  const results = {
    healthCheck: false,
    createProduct: null,
    getProducts: false,
    getProductById: false,
    sellingHistory: false,
    filtering: false
  };
  
  // 1. Health check
  results.healthCheck = await testHealthCheck();
  if (!results.healthCheck) {
    console.log('\n❌ Server is not running. Please start the test server first:');
    console.log('   cd farmkart-backend && node test-server.js');
    return;
  }
  
  // 2. Create product
  results.createProduct = await testCreateProduct();
  
  // 3. Get all products
  const products = await testGetProducts();
  results.getProducts = products.length > 0;
  
  // 4. Get product by ID
  if (results.createProduct) {
    const product = await testGetProductById(results.createProduct);
    results.getProductById = product !== null;
  }
  
  // 5. Get selling history
  const history = await testGetSellingHistory();
  results.sellingHistory = history.length > 0;
  
  // 6. Test filtering
  results.filtering = await testProductFiltering();
  
  // Summary
  console.log('\n📋 TEST SUMMARY');
  console.log('================');
  console.log(`✅ Health Check: ${results.healthCheck ? 'PASS' : 'FAIL'}`);
  console.log(`✅ Create Product: ${results.createProduct ? 'PASS' : 'FAIL'}`);
  console.log(`✅ Get Products: ${results.getProducts ? 'PASS' : 'FAIL'}`);
  console.log(`✅ Get Product by ID: ${results.getProductById ? 'PASS' : 'FAIL'}`);
  console.log(`✅ Selling History: ${results.sellingHistory ? 'PASS' : 'FAIL'}`);
  console.log(`✅ Product Filtering: ${results.filtering ? 'PASS' : 'FAIL'}`);
  
  const passCount = Object.values(results).filter(r => r === true || r !== null && r !== false).length;
  const totalCount = Object.keys(results).length;
  
  console.log(`\n🎯 Overall: ${passCount}/${totalCount} tests passed`);
  
  if (passCount === totalCount) {
    console.log('🎉 All tests passed! The API is working correctly.');
  } else {
    console.log('⚠️  Some tests failed. Check the logs above for details.');
  }
}

// Run tests if this file is executed directly
if (require.main === module) {
  runTests().catch(console.error);
}

module.exports = { runTests };