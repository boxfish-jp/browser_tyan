import { serve } from "@hono/node-server";
import { Hono } from "hono";
import { chromium } from "playwright";

const app = new Hono();

const PROFILE_DIR = "/app/browser-profile";

app.get("/", async (c) => {
	let context: Awaited<
		ReturnType<typeof chromium.launchPersistentContext>
	> | null = null;
	try {
		context = await chromium.launchPersistentContext("/app/browser-profile", {
			//headless: false,
			args: ["--no-sandbox", "--disable-gpu", "--disable-dev-shm-usage"],
		});
		const page = await context.newPage();

		await page.goto("https://live.nicovideo.jp/watch/user/98746932");
		const data = await page.evaluate(() => {
			const scriptTag = document.getElementById("embedded-data");
			return scriptTag ? scriptTag.getAttribute("data-props") : null;
		});
		if (!data) {
			console.error("Failed to get data from the page");
			return c.text("Failed to get data from the page");
		}
		const jsonData = JSON.parse(data);
		const nicoWsurl = jsonData.site.relive.webSocketUrl as string;
		const vposBaseTime = jsonData.program.vposBaseTime as number;
		const liveId = jsonData.program.nicoliveProgramId as string;

		const result = { nicoWsurl, vposBaseTime, liveId };
		console.log(result);
		return c.text(JSON.stringify(result));
	} finally {
		if (context) {
			await context.close();
		}
	}
});

app.get("/hand", async (c) => {
	console.log("🚀 GUI ブラウザを起動します。手動でログインしてください。");
	console.log(
		"   完了後、ブラウザウィンドウを閉じるとスクリプトが終了します。",
	);

	const context = await chromium.launchPersistentContext(PROFILE_DIR, {
		headless: false, // 👈 GUI 表示
		slowMo: 300, // 操作しやすくするため遅延
		args: ["--disable-gpu", "--disable-dev-shm-usage"], // sandbox はホストなら不要な場合も
	});

	const page = await context.newPage();
	await page.goto("https://google.com");

	// 👇 ブラウザが閉じられるまで待機（手動ログイン用）
	await new Promise<void>((resolve) => {
		context.on("close", () => resolve());
	});

	console.log("✅ ログイン状態をプロファイルに保存しました。");
	console.log(`📁 保存先: ${PROFILE_DIR}`);
	await context.close();

	return c.text("ok");
});

serve(
	{
		fetch: app.fetch,
		port: 3000,
	},
	(info) => {
		console.log(`Server is running on http://localhost:${info.port}`);
	},
);
