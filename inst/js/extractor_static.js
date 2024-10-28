const axios = require('axios');
const fs = require('fs').promises;
const { Readability } = require('@mozilla/readability');
const { parseHTML } = require('linkedom');
const { JSDOM } = require("jsdom");

const url = process.argv[2];
const outputFilename = process.argv[3] || 'article.json';

async function fetchHTML(url) {
    try {
        const response = await axios.get(url);
        return response.data;
    } catch (err) {
        console.error(`Error fetching the HTML from ${url}:`, err.message);
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

async function extractArticle(url, outputFilename) {
    try {
        const html = await fetchHTML(url);
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

extractArticle(url, outputFilename);
