/**
 * Model Validation Test Script
 * Validates that data models match between Flutter and backend
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// Configuration
const BACKEND_MODELS_DIR = path.resolve(__dirname, '../src/models');
const FLUTTER_MODELS_DIR = path.resolve(__dirname, '../../lib/models');

// Test Results Tracking
const results = {
  total: 0,
  passed: 0,
  failed: 0
};

// Model mappings between Flutter and Node.js
const modelMappings = [
  {
    backendModel: 'user.model.js',
    flutterModel: 'user_model.dart',
    keyFields: [
      { backend: 'name', flutter: 'name' },
      { backend: 'email', flutter: 'email' },
      { backend: 'dateOfBirth', flutter: 'dateOfBirth' },
      { backend: 'gender', flutter: 'gender' },
      { backend: 'weight', flutter: 'weight' },
      { backend: 'height', flutter: 'height' },
      { backend: 'healthConditions', flutter: 'healthConditions' },
      { backend: 'isAdmin', flutter: 'isAdmin' },
      { backend: 'profileImageUrl', flutter: 'profileImageUrl' }
    ]
  },
  {
    backendModel: 'sleep-data.model.js',
    flutterModel: 'sleep_data_model.dart',
    keyFields: [
      { backend: 'userId', flutter: 'userId' },
      { backend: 'date', flutter: 'date' },
      { backend: 'bedTime', flutter: 'bedTime' },
      { backend: 'wakeUpTime', flutter: 'wakeUpTime' },
      { backend: 'sleepDuration', flutter: 'sleepDuration' },
      { backend: 'timeToFallAsleep', flutter: 'timeToFallAsleep' },
      { backend: 'interruptionCount', flutter: 'interruptionCount' },
      { backend: 'sleepQuality', flutter: 'sleepQuality' },
      { backend: 'stressLevel', flutter: 'stressLevel' }
    ]
  },
  {
    backendModel: 'prediction.model.js',
    flutterModel: 'prediction_model.dart',
    keyFields: [
      { backend: 'userId', flutter: 'userId' },
      { backend: 'predictionScore', flutter: 'predictionScore' },
      { backend: 'interruptionWindows', flutter: 'interruptionWindows' },
      { backend: 'contributingFactors', flutter: 'contributingFactors' },
      { backend: 'recommendations', flutter: 'recommendations' },
      { backend: 'inputData', flutter: 'inputData' }
    ]
  }
];

// Test runner
function runTest(name, testFn) {
  results.total++;
  console.log(`\n🧪 Running test: ${name}`);
  try {
    testFn();
    console.log(`✅ Test passed: ${name}`);
    results.passed++;
  } catch (error) {
    console.error(`❌ Test failed: ${name}`);
    console.error('  Error:', error.message);
    results.failed++;
  }
}

// Check if a file exists
function fileExists(filePath) {
  try {
    fs.accessSync(filePath, fs.constants.F_OK);
    return true;
  } catch (error) {
    return false;
  }
}

// Read and parse backend model
function readBackendModel(modelFileName) {
  const filePath = path.join(BACKEND_MODELS_DIR, modelFileName);
  if (!fileExists(filePath)) {
    throw new Error(`Backend model file not found: ${filePath}`);
  }
  
  const content = fs.readFileSync(filePath, 'utf8');
  
  // Extract schema fields using regular expressions
  const schemaFields = {};
  const schemaRegex = /const \w+Schema = new mongoose\.Schema\(\{([\s\S]*?)\}\s*,\s*\{/;
  const fieldRegex = /\s+(\w+):\s*\{([^{}]*(?:\{[^{}]*\}[^{}]*)*)\}/g;
  
  const schemaMatch = schemaRegex.exec(content);
  if (!schemaMatch) {
    throw new Error(`Could not extract schema from ${modelFileName}`);
  }
  
  const schemaContent = schemaMatch[1];
  let fieldMatch;
  
  while ((fieldMatch = fieldRegex.exec(schemaContent)) !== null) {
    const fieldName = fieldMatch[1];
    const fieldContent = fieldMatch[2];
    
    const typeMatch = /type:\s*(\w+)/.exec(fieldContent);
    const requiredMatch = /required:\s*(true|false)/.exec(fieldContent);
    const defaultMatch = /default:([^,}]+)/.exec(fieldContent);
    
    schemaFields[fieldName] = {
      type: typeMatch ? typeMatch[1] : 'Unknown',
      required: requiredMatch ? requiredMatch[1] === 'true' : false,
      hasDefault: defaultMatch !== null
    };
  }
  
  return schemaFields;
}

// Read and parse Flutter model
function readFlutterModel(modelFileName) {
  const filePath = path.join(FLUTTER_MODELS_DIR, modelFileName);
  if (!fileExists(filePath)) {
    throw new Error(`Flutter model file not found: ${filePath}`);
  }
  
  const content = fs.readFileSync(filePath, 'utf8');
  
  // Extract class fields using regular expressions
  const fields = {};
  const classNameRegex = /class\s+(\w+)\s+\{/;
  const fieldRegex = /\s+(final|static|const)?\s*([\w<>?]+)\s+(\w+)(\s*=\s*[^;]+)?;/g;
  
  const classMatch = classNameRegex.exec(content);
  if (!classMatch) {
    throw new Error(`Could not extract class from ${modelFileName}`);
  }
  
  let fieldMatch;
  while ((fieldMatch = fieldRegex.exec(content)) !== null) {
    const fieldModifier = fieldMatch[1] || '';
    const fieldType = fieldMatch[2];
    const fieldName = fieldMatch[3];
    const fieldDefault = fieldMatch[4];
    
    if (fieldModifier !== 'static' && !fieldName.startsWith('_')) {
      fields[fieldName] = {
        type: fieldType,
        hasDefault: fieldDefault !== undefined && fieldDefault !== null
      };
    }
  }
  
  // Check for fromJson and toJson methods
  const hasFromJson = content.includes('fromJson') && content.includes('Map<String, dynamic>');
  const hasToJson = content.includes('toJson') && content.includes('Map<String, dynamic>');
  
  return {
    fields,
    hasFromJson,
    hasToJson
  };
}

// Compare field types between Flutter and Node.js
function compareFieldTypes(backendType, flutterType) {
  // Map of backend types to expected Flutter types
  const typeMapping = {
    'String': ['String', 'String?'],
    'Number': ['int', 'int?', 'double', 'double?', 'num', 'num?'],
    'Date': ['DateTime', 'DateTime?'],
    'Boolean': ['bool', 'bool?'],
    'Array': ['List', 'List<dynamic>', 'List<String>', 'List<int>', 'List<double>', 'List<Map<String, dynamic>>']
  };
  
  // Check if Flutter type matches expected type for backend type
  if (!backendType || !flutterType) return false;
  
  for (const [backend, flutter] of Object.entries(typeMapping)) {
    if (backendType.includes(backend) && flutter.some(type => flutterType.includes(type))) {
      return true;
    }
  }
  
  return false;
}

// Validate models match between Flutter and backend
function validateModels(mapping) {
  console.log(`  Validating ${mapping.backendModel} against ${mapping.flutterModel}`);
  
  const backendFields = readBackendModel(mapping.backendModel);
  const flutterModel = readFlutterModel(mapping.flutterModel);
  
  // Check for JSON serialization methods
  if (!flutterModel.hasFromJson) {
    console.warn(`  Warning: ${mapping.flutterModel} is missing fromJson method`);
  }
  
  if (!flutterModel.hasToJson) {
    console.warn(`  Warning: ${mapping.flutterModel} is missing toJson method`);
  }
  
  // Check for required key fields
  for (const field of mapping.keyFields) {
    console.log(`  Checking field mapping: ${field.backend} (backend) => ${field.flutter} (flutter)`);
    
    const backendField = backendFields[field.backend];
    const flutterField = flutterModel.fields[field.flutter];
    
    if (!backendField) {
      throw new Error(`Backend field '${field.backend}' not found in ${mapping.backendModel}`);
    }
    
    if (!flutterField) {
      throw new Error(`Flutter field '${field.flutter}' not found in ${mapping.flutterModel}`);
    }
    
    if (!compareFieldTypes(backendField.type, flutterField.type)) {
      console.warn(
        `  Warning: Type mismatch for ${field.backend}/${field.flutter}: ` +
        `Backend (${backendField.type}) vs Flutter (${flutterField.type})`
      );
    }
    
    if (backendField.required && !flutterField.hasDefault && !flutterField.type.includes('?')) {
      console.log(`  ✓ Field ${field.flutter} correctly marked as required in Flutter`);
    } else if (backendField.required && (flutterField.hasDefault || flutterField.type.includes('?'))) {
      console.warn(
        `  Warning: Field ${field.backend} is required in backend but nullable or has default in Flutter`
      );
    }
  }
}

// Validate date formats are ISO 8601
function validateDateFormats() {
  // Look for date parsing in Flutter code
  const flutterFiles = findFilesRecursive(FLUTTER_MODELS_DIR, '.dart');
  let hasNonIsoFormat = false;
  
  for (const file of flutterFiles) {
    const content = fs.readFileSync(file, 'utf8');
    
    // Look for date parsing that doesn't use ISO 8601
    if (content.includes('DateTime.parse') || content.includes('DateTime.tryParse')) {
      console.log(`  ✓ Found ISO 8601 date parsing in ${path.basename(file)}`);
    } else if (content.includes('DateTime') && 
              (content.includes('intl') || content.includes('DateFormat'))) {
      console.warn(`  Warning: Non-ISO date format may be used in ${path.basename(file)}`);
      hasNonIsoFormat = true;
    }
  }
  
  // Look for date formatting in backend code
  const backendFiles = findFilesRecursive(BACKEND_MODELS_DIR, '.js');
  
  for (const file of backendFiles) {
    const content = fs.readFileSync(file, 'utf8');
    
    // Look for date formatting that doesn't use ISO 8601
    if (content.includes('.toISOString()')) {
      console.log(`  ✓ Found ISO 8601 date formatting in ${path.basename(file)}`);
    } else if (content.includes('Date') && 
              (content.includes('toLocaleDateString') || 
               content.includes('toLocaleTimeString') ||
               content.includes('moment'))) {
      console.warn(`  Warning: Non-ISO date format may be used in ${path.basename(file)}`);
      hasNonIsoFormat = true;
    }
  }
  
  if (hasNonIsoFormat) {
    throw new Error('Some files may use non-ISO 8601 date formats');
  }
}

// Helper function to find files recursively
function findFilesRecursive(dir, extension) {
  let results = [];
  const files = fs.readdirSync(dir);
  
  for (const file of files) {
    const filePath = path.join(dir, file);
    const stat = fs.statSync(filePath);
    
    if (stat.isDirectory()) {
      results = results.concat(findFilesRecursive(filePath, extension));
    } else if (file.endsWith(extension)) {
      results.push(filePath);
    }
  }
  
  return results;
}

// Run all model validation tests
function runAllTests() {
  console.log('🚀 Starting Data Model Validation Tests');
  
  // Check directories exist
  if (!fileExists(BACKEND_MODELS_DIR)) {
    console.error(`Backend models directory not found: ${BACKEND_MODELS_DIR}`);
    process.exit(1);
  }
  
  if (!fileExists(FLUTTER_MODELS_DIR)) {
    console.error(`Flutter models directory not found: ${FLUTTER_MODELS_DIR}`);
    process.exit(1);
  }
  
  // Validate all model mappings
  for (const mapping of modelMappings) {
    runTest(`Validate ${mapping.backendModel} against ${mapping.flutterModel}`, () => {
      validateModels(mapping);
    });
  }
  
  // Validate date formats
  runTest('Validate ISO 8601 Date Formats', validateDateFormats);
  
  // Print summary
  console.log('\n📊 Test Summary:');
  console.log(`Total: ${results.total}`);
  console.log(`Passed: ${results.passed}`);
  console.log(`Failed: ${results.failed}`);
  
  if (results.failed > 0) {
    console.log('\n❌ Some validations failed!');
    process.exit(1);
  } else {
    console.log('\n✅ All validations passed!');
  }
}

// Run validation tests
runAllTests();
