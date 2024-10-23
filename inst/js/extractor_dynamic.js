const puppeteer = require('puppeteer');
const fs = require('fs');
const { Readability } = require('@mozilla/readability');
const { JSDOM } = require('jsdom');

const url = process.argv[2];
const outputFilename = process.argv[3] || 'article.json';

async function extractArticle(url, outputFilename) {

    const browser = await puppeteer.launch();
    const page = await browser.newPage();

    await page.goto(url, { waitUntil: 'networkidle2' });

    const html = await page.content();

    await browser.close();

    const dom = new JSDOM(html, { url });

    const reader = new Readability(dom.window.document);
    const article = reader.parse();

    fs.writeFileSync(outputFilename, JSON.stringify(article, null, 2));

    console.log(`Article saved to ${outputFilename}`);
}

extractArticle(url, outputFilename)
    .catch(err => {
        console.error('Error:', err);
    });
