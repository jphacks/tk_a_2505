import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
const corsHeaders = {
	"Access-Control-Allow-Origin": "*",
	"Access-Control-Allow-Headers":
		"authorization, x-client-info, apikey, content-type",
};
// Valid disaster types matching the enum
const DISASTER_TYPES = [
	"Flood",
	"Landslide",
	"Storm Surge",
	"Earthquake",
	"Tsunami",
	"Fire",
	"Inland Flood",
	"Volcano",
	"Zombie",
];
const systemPrompt = `あなたは防災訓練アプリのミッション生成AIです。指定された災害に備えるための現実的で魅力的なミッションシナリオを生成してください。

以下の正確な構造でJSONレスポンスを返してください：
{
  "title": "簡潔で魅力的なミッションタイトル（最大60文字）",
  "overview": "シナリオ、目標、ユーザーが行うべきことを説明する詳細なミッション説明（2-3文）",
  "disaster_type": "プロンプトで指定された災害タイプをそのまま使用"
}

要件:
- タイトルは行動指向で簡潔に（日本語で記述）
- 概要は情報的で動機付けとなるように（日本語で記述）
- 災害タイプはプロンプトで指定されたものを正確に使用すること（英語、大文字小文字区別）
- ミッションは指定された災害に特化した教育的で実用的な内容に
- 実際の防災シナリオに焦点を当てること`;
serve(async (req) => {
	console.log("[START] Generate Mission (Japanese) edge function invoked");
	console.log("[REQUEST] Method:", req.method);
	console.log("[REQUEST] URL:", req.url);
	// Handle CORS preflight
	if (req.method === "OPTIONS") {
		console.log("[CORS] Handling OPTIONS preflight request");
		return new Response("ok", {
			headers: corsHeaders,
		});
	}
	try {
		console.log("[PARSE] Attempting to parse request body...");
		const { context, disaster_type_hint } = await req.json();
		console.log("[PARSE] Request body parsed successfully");
		console.log(
			"[CONTEXT] Received:",
			context || "none (will generate random mission)"
		);
		console.log(
			"[DISASTER_TYPE_HINT] Received:",
			disaster_type_hint || "none (will be randomly selected)"
		);

		// Randomly select a disaster type from the list
		const selectedDisasterType =
			disaster_type_hint ||
			DISASTER_TYPES[Math.floor(Math.random() * DISASTER_TYPES.length)];
		console.log(
			"[DISASTER_TYPE] Selected disaster type:",
			selectedDisasterType
		);
		// Get the authorization header to authenticate the user
		console.log("[AUTH] Extracting authorization token...");
		const authHeader = req.headers.get("authorization");
		if (!authHeader) {
			console.error("[AUTH] No authorization header found");
			return new Response(
				JSON.stringify({
					error: "Authorization header is required.",
				}),
				{
					headers: {
						...corsHeaders,
						"Content-Type": "application/json",
					},
					status: 401,
				}
			);
		}
		// Initialize Supabase client
		console.log("[SUPABASE] Initializing Supabase client...");
		const supabaseUrl = Deno.env.get("SUPABASE_URL");
		const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
		if (!supabaseUrl || !supabaseServiceKey) {
			throw new Error("Supabase credentials not found in environment");
		}
		const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey);
		// Create a client with the user's token to get their user ID
		const supabaseUser = createClient(supabaseUrl, supabaseServiceKey, {
			global: {
				headers: {
					Authorization: authHeader,
				},
			},
		});
		// Get the authenticated user
		console.log("[AUTH] Getting authenticated user...");
		const {
			data: { user },
			error: userError,
		} = await supabaseUser.auth.getUser();
		if (userError || !user) {
			console.error("[AUTH] Failed to get user:", userError);
			return new Response(
				JSON.stringify({
					error: "Failed to authenticate user.",
				}),
				{
					headers: {
						...corsHeaders,
						"Content-Type": "application/json",
					},
					status: 401,
				}
			);
		}
		console.log("[AUTH] User authenticated, ID:", user.id);
		// Build the user query for Gemini (Japanese)
		let userQuery = `${selectedDisasterType}災害に関するミッションシナリオを生成してください`;
		if (context) {
			userQuery += `。次の文脈に基づいて: ${context}`;
		}
		userQuery += `。disaster_typeは必ず「${selectedDisasterType}」を使用すること。`;
		const fullPrompt = `${systemPrompt}\n\n${userQuery}`;
		console.log(
			"[PROMPT] Full prompt length:",
			fullPrompt.length,
			"characters"
		);
		// Call the Gemini edge function
		console.log("[GEMINI] Calling Gemini edge function...");
		const geminiUrl = `${supabaseUrl}/functions/v1/gemini-llm`;
		const geminiResponse = await fetch(geminiUrl, {
			method: "POST",
			headers: {
				"Content-Type": "application/json",
				Authorization: authHeader,
			},
			body: JSON.stringify({
				prompt: fullPrompt,
			}),
		});
		if (!geminiResponse.ok) {
			const errorText = await geminiResponse.text();
			console.error("[GEMINI] Error response:", errorText);
			throw new Error(`Gemini API call failed: ${geminiResponse.statusText}`);
		}
		const geminiData = await geminiResponse.json();
		console.log("[GEMINI] Response received");
		const scenarioText = geminiData.scenario;
		console.log("[SCENARIO] Raw text:", scenarioText);
		// Parse the JSON response from Gemini
		let missionData;
		try {
			// Try to extract JSON if it's wrapped in markdown code blocks
			const jsonMatch =
				scenarioText.match(/```json\s*([\s\S]*?)\s*```/) ||
				scenarioText.match(/```\s*([\s\S]*?)\s*```/);
			const jsonText = jsonMatch ? jsonMatch[1] : scenarioText;
			missionData = JSON.parse(jsonText.trim());
			console.log("[PARSE] Mission data parsed:", missionData);
		} catch (parseError) {
			console.error(
				"[PARSE] Failed to parse Gemini response as JSON:",
				parseError
			);
			throw new Error("Failed to parse mission data from Gemini response");
		}

		// Use the pre-selected disaster type directly (more reliable than Gemini's response)
		console.log(
			"[DISASTER_TYPE] Using pre-selected disaster type:",
			selectedDisasterType
		);

		// Insert into missions table
		console.log("[DATABASE] Inserting mission into database...");
		const { data: missionRecord, error: insertError } = await supabaseAdmin
			.from("missions")
			.insert({
				user_id: user.id,
				title: missionData.title,
				overview: missionData.overview,
				disaster_type: selectedDisasterType,
				status: "have",
			})
			.select()
			.single();
		if (insertError) {
			console.error("[DATABASE] Error inserting mission:", insertError);
			throw insertError;
		}
		console.log("[DATABASE] Mission created with ID:", missionRecord.id);
		// Transform the mission record to use epoch timestamp for created_at
		// Swift can decode epoch timestamps directly as Date
		const transformedMission = {
			...missionRecord,
			created_at: new Date().getTime() / 1000, // Convert to seconds (epoch timestamp)
		};
		// Return the created mission
		const responseBody = {
			mission: transformedMission,
			generated_prompt: fullPrompt,
		};
		// ===== DEBUG: Log the exact JSON structure being returned =====
		console.log("[RESPONSE] Complete response body structure:");
		console.log(
			"[RESPONSE] JSON.stringify(responseBody):",
			JSON.stringify(responseBody, null, 2)
		);
		console.log("[RESPONSE] Mission object details:");
		console.log(
			"[RESPONSE]   - id:",
			missionRecord.id,
			"type:",
			typeof missionRecord.id
		);
		console.log(
			"[RESPONSE]   - user_id:",
			missionRecord.user_id,
			"type:",
			typeof missionRecord.user_id
		);
		console.log(
			"[RESPONSE]   - title:",
			missionRecord.title,
			"type:",
			typeof missionRecord.title
		);
		console.log(
			"[RESPONSE]   - overview:",
			missionRecord.overview,
			"type:",
			typeof missionRecord.overview
		);
		console.log(
			"[RESPONSE]   - disaster_type:",
			missionRecord.disaster_type,
			"type:",
			typeof missionRecord.disaster_type
		);
		console.log(
			"[RESPONSE]   - status:",
			missionRecord.status,
			"type:",
			typeof missionRecord.status
		);
		console.log(
			"[RESPONSE]   - created_at:",
			missionRecord.created_at,
			"type:",
			typeof missionRecord.created_at
		);
		console.log(
			"[NOTE] Steps and distances are now tracked in mission_results table when mission is completed"
		);
		// ===== END DEBUG =====
		console.log("[COMPLETE] Sending successful response to client");
		return new Response(JSON.stringify(responseBody), {
			headers: {
				...corsHeaders,
				"Content-Type": "application/json",
			},
			status: 200,
		});
	} catch (error) {
		console.error("[EXCEPTION] Error caught in main handler");
		console.error("[EXCEPTION] Error type:", error.constructor.name);
		console.error("[EXCEPTION] Error message:", error.message);
		console.error("[EXCEPTION] Error stack:", error.stack);
		return new Response(
			JSON.stringify({
				error: error.message,
			}),
			{
				headers: {
					...corsHeaders,
					"Content-Type": "application/json",
				},
				status: 500,
			}
		);
	}
});
