const puppeteer = require('puppeteer');
const fs = require('fs');
const { Readability } = require('@mozilla/readability');
const { parseHTML } = require('linkedom');

const url = process.argv[2];
const outputFilename = process.argv[3] || 'article.json';

async function extractArticle(url, outputFilename) {

    const browser = await puppeteer.launch();
    const page = await browser.newPage();

    await page.goto(url, { waitUntil: 'networkidle2' });

    const html = await page.content();

    await browser.close();

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
}

extractArticle(url, outputFilename)
    .catch(err => {
        console.error('Error:', err);
    });
