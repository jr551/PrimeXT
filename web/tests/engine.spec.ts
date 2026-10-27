import { test, expect } from '@playwright/test';
import path from 'node:path';
import fs from 'node:fs';

test('Uplink demo loads Xash + PrimeXT WASM without fatal errors', async ({
  page,
}) => {
  const errors: string[] = [];
  page.on('pageerror', (err) => errors.push(String(err)));
  page.on('console', (msg) => {
    if (msg.type() === 'error') errors.push(msg.text());
  });

  await page.goto('/?autotest=1', { waitUntil: 'domcontentloaded' });

  await expect(page.locator('#status')).toHaveText('Running', {
    timeout: 120_000,
  });

  await expect
    .poll(
      async () =>
        page.evaluate(() => {
          const x = (window as unknown as { __primextXash?: { running: boolean; exited: boolean } })
            .__primextXash;
          return x?.running === true && x?.exited !== true;
        }),
      { timeout: 60_000 },
    )
    .toBe(true);

  await page.waitForTimeout(8_000);

  const fatal = errors.filter(
    (e) =>
      /fatal|abort|Aborted|RuntimeError|missing essential exports|can't init client API/i.test(
        e,
      ) && !/WebGL/i.test(e),
  );
  expect(fatal).toEqual([]);

  const shotDir = path.join(process.cwd(), 'test-results');
  fs.mkdirSync(shotDir, { recursive: true });
  await page.screenshot({
    path: path.join(shotDir, 'primext-engine.png'),
    fullPage: true,
  });

  const log = await page.locator('#log').innerText();
  expect(log).toMatch(/Starting Xash main loop/i);

  const view = page.locator('#canvas');
  await view.click();
  await page.keyboard.press('Escape');
  await page.waitForTimeout(1_500);

  const fatalAfterInput = errors.filter(
    (e) =>
      /fatal|abort|Aborted|RuntimeError|missing essential exports|can't init client API/i.test(
        e,
      ) && !/WebGL/i.test(e),
  );
  expect(fatalAfterInput).toEqual([]);
  await expect
    .poll(
      async () =>
        page.evaluate(() => {
          const x = (window as unknown as { __primextXash?: { running: boolean; exited: boolean } })
            .__primextXash;
          return x?.running === true && x?.exited !== true;
        }),
      { timeout: 10_000 },
    )
    .toBe(true);

  await page.screenshot({
    path: path.join(shotDir, 'primext-input.png'),
    fullPage: true,
  });
});
