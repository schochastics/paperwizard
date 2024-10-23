const axios = require('axios');
const fs = require('fs');
const { Readability } = require('@mozilla/readability');
const { JSDOM } = require('jsdom');

const url = process.argv[2];
const outputFilename = process.argv[3] || 'article.json';

async function extractArticle(url, outputFilename) {
    try {

        const response = await axios.get(url);
        const html = response.data;

        const dom = new JSDOM(html, { url });


        const reader = new Readability(dom.window.document);
        const article = reader.parse();

        fs.writeFileSync(outputFilename, JSON.stringify(article, null, 2));

        console.log(`Article saved to ${outputFilename}`);
    } catch (err) {
        console.error(`Error fetching or parsing the article: ${err.message}`);
    }
}

extractArticle(url, outputFilename);