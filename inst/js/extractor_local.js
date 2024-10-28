const fs = require('fs').promises;
const { Readability } = require('@mozilla/readability');
const { parseHTML } = require('linkedom');
const { JSDOM } = require("jsdom");

const inputHTMLFile = process.argv[2];
const outputFilename = process.argv[3] || 'article.json';

async function readHTMLFile(filepath) {
    try {
        return await fs.readFile(filepath, "utf-8");
    } catch (err) {
        console.error(`Error reading the HTML file ${filepath}:`, err.message);
        throw err;
    }
}

function extractPublishedTime(html) {
    const dom = new JSDOM(html);
    const timeElement = dom.window.document.querySelector('time');
    if (timeElement) {
        return timeElement.getAttribute('datetime') || timeElement.textContent || null;
    }
    return null;
}

async function extractArticle(inputHTMLFile, outputFilename) {
    try {
        const html = await readHTMLFile(inputHTMLFile);
        const { document } = parseHTML(html);

        const reader = new Readability(document);
        const article = reader.parse();

        if (!article.publishedTime) {
            article.publishedTime = extractPublishedTime(html);
        }

        await fs.writeFile(outputFilename, JSON.stringify(article, null, 2));
        console.log(`Article saved to ${outputFilename}`);

    } catch (err) {
        console.error(`Error processing the article: ${err.message}`);
    }
}

extractArticle(inputHTMLFile, outputFilename);
