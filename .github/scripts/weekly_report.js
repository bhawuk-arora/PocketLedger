const https = require('https');

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_ANON_KEY;
const resendApiKey = process.env.RESEND_API_KEY;
const toEmail = process.env.TO_EMAIL;
const userId = process.env.USER_ID;

if (!supabaseUrl || !supabaseKey || !resendApiKey || !toEmail) {
  console.error("Missing required environment variables!");
  process.exit(1);
}

// Calculate query start date dynamically based on input range
const customStart = process.env.START_DATE;
const customEnd = process.env.END_DATE;

let dateString;
if (customStart) {
  const startObj = new Date(customStart);
  const endObj = customEnd ? new Date(customEnd) : new Date(startObj.getTime() + 7 * 24 * 60 * 60 * 1000);
  const durationMs = endObj.getTime() - startObj.getTime();
  // Fetch from startObj minus durationMs to support comparison
  const fetchStart = new Date(startObj.getTime() - durationMs);
  dateString = fetchStart.toISOString();
} else {
  const fourteenDaysAgo = new Date();
  fourteenDaysAgo.setDate(fourteenDaysAgo.getDate() - 14);
  dateString = fourteenDaysAgo.toISOString();
}

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
    // Supabase query to get expenses of last 14 days
    let queryUrl = `${supabaseUrl}/rest/v1/expenses?date=gte.${dateString}&select=*`;
    if (userId) {
      queryUrl += `&user_id=eq.${userId}`;
      console.log(`Filtering query for user_id: ${userId}`);
    }
    const supabaseHeaders = {
      'apikey': supabaseKey,
      'Authorization': `Bearer ${supabaseKey}`,
      'Content-Type': 'application/json'
    };

    console.log("Fetching expenses from Supabase...");
    const expenses = await makeRequest(queryUrl, supabaseHeaders);
    console.log(`Fetched ${expenses.length} expenses from past 14 days.`);

    let startObj, endObj;
    if (customStart) {
      startObj = new Date(customStart);
      endObj = customEnd ? new Date(customEnd) : new Date(startObj.getTime() + 7 * 24 * 60 * 60 * 1000);
    } else {
      endObj = new Date();
      startObj = new Date();
      startObj.setDate(endObj.getDate() - 7);
    }

    const durationMs = endObj.getTime() - startObj.getTime();
    const prevStartObj = new Date(startObj.getTime() - durationMs);
    const prevEndObj = startObj;

    // Format Date Range Nice String (e.g. 12 Jul 2026 - 19 Jul 2026)
    const dateOptions = { day: '2-digit', month: 'short', year: 'numeric' };
    const periodStart = startObj.toLocaleDateString('en-IN', dateOptions);
    const periodEnd = endObj.toLocaleDateString('en-IN', dateOptions);
    const datePeriodString = `${periodStart} - ${periodEnd}`;

    // Split into Current Period (Week 1) and Previous Period (Week 2)
    const week1Expenses = [];
    const week2Expenses = [];

    expenses.forEach(exp => {
      const expDate = new Date(exp.date);
      if (expDate >= startObj && expDate <= endObj) {
        week1Expenses.push(exp);
      } else if (expDate >= prevStartObj && expDate < prevEndObj) {
        week2Expenses.push(exp);
      }
    });

    if (week1Expenses.length === 0) {
      console.log(`No expenses recorded in the selected period: ${datePeriodString}!`);
      await sendEmptyReportEmail(datePeriodString);
      return;
    }

    // Process Week 1 (Latest Week)
    let totalWeek1 = 0;
    const categoryBreakdown = {};
    let biggestExpense = { amount: 0, place: 'N/A', category: 'N/A' };

    week1Expenses.forEach(exp => {
      const amount = parseFloat(exp.amount || 0);
      totalWeek1 += amount;

      const cat = exp.category || 'Miscellaneous';
      categoryBreakdown[cat] = (categoryBreakdown[cat] || 0) + amount;

      if (amount > biggestExpense.amount) {
        biggestExpense = { amount, place: exp.place || 'Unknown', category: cat };
      }
    });

    // Process Week 2 (Comparison Week)
    let totalWeek2 = 0;
    week2Expenses.forEach(exp => {
      totalWeek2 += parseFloat(exp.amount || 0);
    });

    // Sort categories by spend amount
    const sortedCategories = Object.entries(categoryBreakdown).sort((a, b) => b[1] - a[1]);

    // Choose funny Punjabi comment based on total spending
    let cheekTitle = "";
    let cheekyComment = "";
    if (totalWeek1 === 0) {
      cheekTitle = "Paise bacha laye paaji! 💸";
      cheekyComment = "Sacchii? Ek bhi kharcha nahi? Dil khush kar ditta!";
    } else if (totalWeek1 < 2000) {
      cheekTitle = "Control ch hai kharcha! 🧘‍♂️";
      cheekyComment = "Bhawuk paaji, tussi te kamaal kar ditta! Wallet haseen lag rha hai.";
    } else if (totalWeek1 < 5000) {
      cheekTitle = "Halke-Phulke jhatke! ⚡";
      cheekyComment = "Thoda control karo paaji! Rajma Chawal thode ghaat khao, wallet slim ho rha hai.";
    } else {
      cheekTitle = "Damage Report: Diljit Dosanjh level! 🔥🚨";
      cheekyComment = "Oye hoye Bhawuk! Kya tussi poora market khareed lya? Thoda saah lao, paise ped te nahi ugde!";
    }

    // Weekly Trend HTML Comparison
    let trendHtml = "";
    if (totalWeek2 > 0) {
      const diff = totalWeek1 - totalWeek2;
      const percent = Math.abs((diff / totalWeek2) * 100).toFixed(0);
      if (diff > 0) {
        trendHtml = `<div style="color: #FF6B6B; font-size: 13px; font-weight: 700; margin-top: 6px;">📈 Up by ${percent}% compared to last week (+₹${diff.toFixed(2)})</div>`;
      } else if (diff < 0) {
        trendHtml = `<div style="color: #4ADE80; font-size: 13px; font-weight: 700; margin-top: 6px;">📉 Down by ${percent}% compared to last week (-₹${Math.abs(diff).toFixed(2)})</div>`;
      } else {
        trendHtml = `<div style="color: #94A3B8; font-size: 13px; font-weight: 700; margin-top: 6px;">⚖️ Spend is exactly identical to last week!</div>`;
      }
    } else {
      trendHtml = `<div style="color: #94A3B8; font-size: 12px; margin-top: 6px;">ℹ️ Comparing with ₹0.00 from the previous week.</div>`;
    }

    // Daily Average
    const durationDays = Math.max(1, Math.round(durationMs / (24 * 60 * 60 * 1000)));
    const dailyAverage = totalWeek1 / durationDays;


    const emojis = {
      'food': '🍔', 'transport': '🚗', 'shopping': '🛍️',
      'bills': '📨', 'entertainment': '🎬', 'health': '💊',
      'sports': '⚽', 'miscellaneous': '🏷️'
    };

    // Format category HTML list with percentages
    const categoryHtmlList = sortedCategories.map(([cat, amount]) => {
      const emoji = emojis[cat.toLowerCase()] || '💰';
      const percentage = totalWeek1 > 0 ? ((amount / totalWeek1) * 100).toFixed(0) : 0;
      return `
        <tr style="border-bottom: 1px solid rgba(255, 255, 255, 0.04); font-size: 14px; color: #E2E8F0;">
          <td style="padding: 10px 0; font-weight: 500;">${emoji} ${cat}</td>
          <td style="padding: 10px 0; text-align: right; font-weight: 600;">₹${amount.toFixed(2)}</td>
          <td style="padding: 10px 0; text-align: right; color: #94A3B8; font-size: 12px; font-weight: 700;">${percentage}%</td>
        </tr>
      `;
    }).join('');

    // Generate HTML Body
    const htmlBody = `
      <div style="font-family: Arial, sans-serif; background-color: #0F0F14; color: #FFFFFF; padding: 32px; border-radius: 16px; max-width: 500px; margin: 0 auto; border: 1px solid #1F1F2E;">
        <h1 style="color: #FF6B35; font-size: 22px; font-weight: 700; margin-bottom: 4px; text-align: center; letter-spacing: -0.5px;">🦁 Bhawuk da Weekly Damage Report</h1>
        <p style="font-size: 12px; color: #64748B; text-align: center; margin-top: 0; margin-bottom: 8px; font-weight: 600;">📅 ${datePeriodString}</p>
        <p style="font-size: 10px; color: #475569; text-align: center; margin-top: 0; margin-bottom: 24px; text-transform: uppercase; letter-spacing: 1px;">Hisaab-kitab Punjabi style vich!</p>
        
        <div style="background-color: #1A1A24; padding: 24px; border-radius: 12px; border: 1px solid rgba(255, 255, 255, 0.04); text-align: center; margin-bottom: 24px;">
          <h2 style="font-size: 32px; color: #FFFFFF; margin: 0; font-weight: 800; letter-spacing: -1px;">₹${totalWeek1.toFixed(2)}</h2>
          <p style="font-size: 13px; color: #FF6B35; font-weight: 700; margin: 8px 0 0 0; text-transform: uppercase; letter-spacing: 0.5px;">${cheekTitle}</p>
          ${trendHtml}
          <p style="font-size: 12px; color: #94A3B8; margin: 12px 0 0 0; font-style: italic; line-height: 1.4;">"${cheekyComment}"</p>
        </div>

        <table style="width: 100%; border-collapse: collapse; margin-bottom: 24px;">
          <thead>
            <tr style="border-bottom: 2px solid rgba(255, 255, 255, 0.06); font-size: 11px; text-transform: uppercase; color: #64748B; letter-spacing: 0.5px;">
              <th style="text-align: left; padding-bottom: 8px;">Category</th>
              <th style="text-align: right; padding-bottom: 8px;">Amount</th>
              <th style="text-align: right; padding-bottom: 8px;">Breakdown</th>
            </tr>
          </thead>
          <tbody>
            ${categoryHtmlList}
          </tbody>
        </table>

        <div style="background-color: #1A1A24; padding: 16px; border-radius: 10px; font-size: 13px; border: 1px solid rgba(255, 255, 255, 0.02); margin-bottom: 0px;">
          <div style="margin-bottom: 8px; color: #94A3B8;"><strong style="color: #FFFFFF;">📅 Daily Average:</strong> ₹${dailyAverage.toFixed(2)} / day</div>
          <div style="margin-bottom: 8px; color: #94A3B8;"><strong style="color: #FFFFFF;">📍 Waddi Chot 💥 (Biggest Spend):</strong> ${biggestExpense.place} (${biggestExpense.category}) — <span style="color: #FF6B6B; font-weight: 700;">₹${biggestExpense.amount.toFixed(2)}</span></div>
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
      subject: `🦁 Weekly Damage: ₹${totalWeek1.toFixed(0)} (${cheekTitle})`,
      html: htmlBody
    });

    console.log("Email sent successfully!", emailResponse);

  } catch (error) {
    console.error("Failed to run weekly report:", error);
    process.exit(1);
  }
}

async function sendEmptyReportEmail(datePeriodString) {
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
          <h1 style="color: #FF6B35; font-size: 20px; font-weight: 700; margin-bottom: 4px;">🦁 Bhawuk da Weekly Damage Report 💸</h1>
          <p style="font-size: 12px; color: #64748B; margin-top: 0; margin-bottom: 24px; font-weight: 600;">📅 ${datePeriodString}</p>
          <p style="font-size: 32px; color: #FFFFFF; font-weight: 800; margin: 24px 0 12px 0; letter-spacing: -1px;">₹0.00</p>
          <p style="font-size: 14px; color: #4ADE80; font-weight: 600; margin-bottom: 8px;">Sacchii? Ek bhi kharcha nahi? Dil khush kar ditta! 🧘‍♂️</p>
          <p style="font-size: 12px; color: #94A3B8;">Wallet safe hai, aish karo paaji!</p>
        </div>
      `
    });
    console.log("Empty report email sent successfully!");
  } catch (err) {
    console.error("Failed to send empty report email:", err);
    throw err;
  }
}

run();
