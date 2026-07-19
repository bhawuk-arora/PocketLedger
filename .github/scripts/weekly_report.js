const https = require('https');

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_ANON_KEY;
const resendApiKey = process.env.RESEND_API_KEY;
const toEmail = process.env.TO_EMAIL;

if (!supabaseUrl || !supabaseKey || !resendApiKey || !toEmail) {
  console.error("Missing required environment variables!");
  process.exit(1);
}

// Fetch last 7 days of expenses
const oneWeekAgo = new Date();
oneWeekAgo.setDate(oneWeekAgo.getDate() - 7);
const dateString = oneWeekAgo.toISOString();

function makeRequest(url, headers, method, body) {
  return new Promise((resolve, reject) => {
    const parsedUrl = new URL(url);
    const options = {
      hostname: parsedUrl.hostname,
      path: parsedUrl.pathname + parsedUrl.search,
      method: method || 'GET',
      headers: headers
    };

    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => data += chunk);
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve(JSON.parse(data || '{}'));
        } else {
          reject(new Error(`Status: ${res.statusCode}, Body: ${data}`));
        }
      });
    });

    req.on('error', (err) => reject(err));
    if (body) {
      req.write(typeof body === 'string' ? body : JSON.stringify(body));
    }
    req.end();
  });
}

async function run() {
  try {
    // Supabase query to get expenses of last 7 days
    const queryUrl = `${supabaseUrl}/rest/v1/expenses?date=gte.${dateString}&select=*`;
    const supabaseHeaders = {
      'apikey': supabaseKey,
      'Authorization': `Bearer ${supabaseKey}`,
      'Content-Type': 'application/json'
    };

    console.log("Fetching expenses from Supabase...");
    const expenses = await makeRequest(queryUrl, supabaseHeaders);
    console.log(`Fetched ${expenses.length} expenses.`);

    if (expenses.length === 0) {
      console.log("No expenses recorded this week!");
      await sendEmptyReportEmail();
      return;
    }

    // Process expenses
    let totalDamage = 0;
    const categoryBreakdown = {};
    let biggestExpense = { amount: 0, place: 'N/A', category: 'N/A' };

    expenses.forEach(exp => {
      const amount = parseFloat(exp.amount || 0);
      totalDamage += amount;

      const cat = exp.category || 'Miscellaneous';
      categoryBreakdown[cat] = (categoryBreakdown[cat] || 0) + amount;

      if (amount > biggestExpense.amount) {
        biggestExpense = { amount, place: exp.place || 'Unknown', category: cat };
      }
    });

    // Sort categories
    const sortedCategories = Object.entries(categoryBreakdown).sort((a, b) => b[1] - a[1]);

    // Choose funny Punjabi comment based on total spending
    let cheekTitle = "";
    let cheekyComment = "";
    if (totalDamage === 0) {
      cheekTitle = "Paise bacha laye paaji! 💸";
      cheekyComment = "Sacchii? Ek bhi kharcha nahi? Dil khush kar ditta!";
    } else if (totalDamage < 2000) {
      cheekTitle = "Control ch hai kharcha! 🧘‍♂️";
      cheekyComment = "Bhawuk paaji, tussi te kamaal kar ditta! Wallet haseen lag rha hai.";
    } else if (totalDamage < 5000) {
      cheekTitle = "Halke-Phulke jhatke! ⚡";
      cheekyComment = "Thoda control karo paaji! Rajma Chawal thode ghaat khao, wallet slim ho rha hai.";
    } else {
      cheekTitle = "Damage Report: Diljit Dosanjh level! 🔥🚨";
      cheekyComment = "Oye hoye Bhawuk! Kya tussi poora market khareed lya? Thoda saah lao, paise ped te nahi ugde!";
    }

    // Format category HTML list
    const emojis = {
      'food': '🍔', 'transport': '🚗', 'shopping': '🛍️',
      'bills': '📨', 'entertainment': '🎬', 'health': '💊',
      'sports': '⚽', 'miscellaneous': '🏷️'
    };
    const categoryHtmlList = sortedCategories.map(([cat, amount]) => {
      const emoji = emojis[cat.toLowerCase()] || '💰';
      return `<li style="margin: 8px 0; font-size: 14px; color: #E2E8F0;"><strong>${emoji} ${cat}:</strong> ₹${amount.toFixed(2)}</li>`;
    }).join('');

    // Generate HTML Body
    const htmlBody = `
      <div style="font-family: Arial, sans-serif; background-color: #0F0F14; color: #FFFFFF; padding: 32px; border-radius: 16px; max-width: 500px; margin: 0 auto; border: 1px solid #1F1F2E;">
        <h1 style="color: #FF6B35; font-size: 22px; font-weight: 700; margin-bottom: 4px; text-align: center; letter-spacing: -0.5px;">🦁 Bhawuk da Weekly Damage Report</h1>
        <p style="font-size: 11px; color: #64748B; text-align: center; margin-top: 0; margin-bottom: 24px; text-transform: uppercase; letter-spacing: 1px;">Hisaab-kitab Punjabi style vich!</p>
        
        <div style="background-color: #1A1A24; padding: 24px; border-radius: 12px; border: 1px solid rgba(255, 255, 255, 0.04); text-align: center; margin-bottom: 24px;">
          <h2 style="font-size: 32px; color: #FFFFFF; margin: 0; font-weight: 800; letter-spacing: -1px;">₹${totalDamage.toFixed(2)}</h2>
          <p style="font-size: 13px; color: #FF6B35; font-weight: 700; margin: 8px 0 0 0; text-transform: uppercase; letter-spacing: 0.5px;">${cheekTitle}</p>
          <p style="font-size: 12px; color: #94A3B8; margin: 8px 0 0 0; font-style: italic; line-height: 1.4;">"${cheekyComment}"</p>
        </div>
        
        <h3 style="color: #FFFFFF; font-size: 14px; border-bottom: 1px solid rgba(255, 255, 255, 0.06); padding-bottom: 8px; margin-bottom: 12px; font-weight: 700;">Kis type da kharcha 🤔:</h3>
        <ul style="list-style-type: none; padding-left: 0; margin-bottom: 24px;">
          ${categoryHtmlList}
        </ul>
        
        <h3 style="color: #FFFFFF; font-size: 14px; border-bottom: 1px solid rgba(255, 255, 255, 0.06); padding-bottom: 8px; margin-bottom: 12px; font-weight: 700;">Waddi Chot 💥 (Biggest Spend):</h3>
        <div style="background-color: #1A1A24; padding: 16px; border-radius: 10px; font-size: 13px; border: 1px solid rgba(255, 255, 255, 0.02);">
          <div style="margin-bottom: 6px; color: #94A3B8;"><strong style="color: #FFFFFF;">📍 Place:</strong> ${biggestExpense.place}</div>
          <div style="margin-bottom: 6px; color: #94A3B8;"><strong style="color: #FFFFFF;">🍔 Category:</strong> ${biggestExpense.category}</div>
          <div style="color: #94A3B8;"><strong style="color: #FFFFFF;">💰 Amount:</strong> <span style="color: #FF6B6B; font-weight: 700;">₹${biggestExpense.amount.toFixed(2)}</span></div>
        </div>
        
        <div style="text-align: center; margin-top: 32px; font-size: 11px; color: #475569; border-top: 1px solid rgba(255, 255, 255, 0.06); padding-top: 16px;">
          Banaaya with ☕ & galat decisions by Bhawuk 🫡
        </div>
      </div>
    `;

    console.log("Sending email via Resend...");
    const resendHeaders = {
      'Authorization': `Bearer ${resendApiKey}`,
      'Content-Type': 'application/json'
    };

    const emailResponse = await makeRequest('https://api.resend.com/emails', resendHeaders, 'POST', {
      from: "PocketLedger <reports@ledger-reports.bhawukarora.app>",
      to: [toEmail],
      subject: `🦁 Weekly Damage: ₹${totalDamage.toFixed(0)} (${cheekTitle})`,
      html: htmlBody
    });

    console.log("Email sent successfully!", emailResponse);

  } catch (error) {
    console.error("Failed to run weekly report:", error);
    process.exit(1);
  }
}

async function sendEmptyReportEmail() {
  try {
    const resendHeaders = {
      'Authorization': `Bearer ${resendApiKey}`,
      'Content-Type': 'application/json'
    };
    await makeRequest('https://api.resend.com/emails', resendHeaders, 'POST', {
      from: "PocketLedger <reports@ledger-reports.bhawukarora.app>",
      to: [toEmail],
      subject: "🦁 Weekly Damage: ₹0 (Waah!)",
      html: `
        <div style="font-family: Arial, sans-serif; background-color: #0F0F14; color: #FFFFFF; padding: 32px; border-radius: 16px; max-width: 500px; margin: 0 auto; text-align: center; border: 1px solid #1F1F2E;">
          <h1 style="color: #FF6B35; font-size: 20px; font-weight: 700; margin-bottom: 24px;">🦁 Bhawuk da Weekly Damage Report 💸</h1>
          <p style="font-size: 32px; color: #FFFFFF; font-weight: 800; margin: 24px 0 12px 0; letter-spacing: -1px;">₹0.00</p>
          <p style="font-size: 14px; color: #4ADE80; font-weight: 600; margin-bottom: 8px;">Sacchii? Ek bhi kharcha nahi? Dil khush kar ditta! 🧘‍♂️</p>
          <p style="font-size: 12px; color: #94A3B8;">Wallet safe hai, aish karo paaji!</p>
        </div>
      `
    });
    console.log("Empty report email sent successfully!");
  } catch (err) {
    console.error("Failed to send empty report email:", err);
  }
}

run();
