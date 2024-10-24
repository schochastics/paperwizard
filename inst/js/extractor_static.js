const axios = require('axios');
const fs = require('fs');
const { Readability } = require('@mozilla/readability');
const { parseHTML } = require('linkedom');

const url = process.argv[2];
const outputFilename = process.argv[3] || 'article.json';

async function extractArticle(url, outputFilename) {
    try {

        const response = await axios.get(url);
        const html = response.data;

        const { document } = parseHTML(html);

        const reader = new Readability(document);
        const article = reader.parse();
        // Check if article has a publishedTime, if not, manually extract it
        if (!article.publishedTime) {
            const timeElement = document.querySelector('time');

            if (timeElement) {
                const datetime = timeElement.getAttribute('datetime');
                if (datetime) {
                    article.publishedTime = datetime;
                }
            }
        }
        fs.writeFileSync(outputFilename, JSON.stringify(article, null, 2));

    } catch (err) {
        console.error(`Error fetching or parsing the article: ${err.message}`);
    }
}

extractArticle(url, outputFilename);