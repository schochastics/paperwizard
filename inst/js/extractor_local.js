const fs = require('fs');
const { Readability } = require('@mozilla/readability');
const { parseHTML } = require('linkedom');

const inputHTMLFile = process.argv[2];
const outputFilename = process.argv[3] || 'article.json';

async function extractArticle(inputHTMLFile, outputFilename) {
    try {
        // Read the HTML content from the file
        const html = fs.readFileSync(inputHTMLFile, 'utf8');
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

        console.log(`Article saved to ${outputFilename}`);
    } catch (err) {
        console.error(`Error parsing the article: ${err.message}`);
    }
}

extractArticle(inputHTMLFile, outputFilename);
