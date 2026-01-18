import { sql } from "./src/db";

async function checkCouples() {
  // Check all couples for user 22
  const result = await sql`
    SELECT * FROM couples 
    WHERE user1_id = 22 OR user2_id = 22
  `;
  console.log("Couples for user 22:", JSON.stringify(result, null, 2));
  
  // Also check couple_requests
  const requests = await sql`
    SELECT * FROM couple_requests 
    WHERE requester_id = 22 OR target_id = 22
  `;
  console.log("Couple requests:", JSON.stringify(requests, null, 2));
  
  process.exit(0);
}

checkCouples();
