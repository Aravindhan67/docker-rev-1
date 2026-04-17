const fs = require('fs');
const path = require('path');
const dotenv = require('dotenv');

const envPath = path.resolve(process.cwd(), '.env');
console.log('Current Working Directory:', process.cwd());
console.log('.env path resolved to:', envPath);
console.log('.env file exists:', fs.existsSync(envPath));

if (fs.existsSync(envPath)) {
    const content = fs.readFileSync(envPath, 'utf8');
    console.log('.env content length:', content.length);
    console.log('.env content (first 10 chars):', content.substring(0, 10));
    
    const result = dotenv.config();
    if (result.error) {
        console.error('Dotenv error:', result.error);
    } else {
        console.log('Dotenv parsed:', result.parsed);
        console.log('MONGO_URI from process.env:', process.env.MONGO_URI ? 'FOUND (hidden for security)' : 'NOT FOUND');
    }
}
