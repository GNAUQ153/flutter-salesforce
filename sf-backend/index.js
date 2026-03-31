let salesforceAuth = {
    accessToken: null,
    instanceUrl: null,
};

import express from "express";
import dotenv from "dotenv";
import fetch from "node-fetch";

import cors from "cors";

const app = express();
app.use(cors());
app.use(express.json());

dotenv.config();

const PORT = 3000;

app.get("/api/fees", async (req, res) => {
    if (!salesforceAuth.accessToken) {
        return res.status(401).json({ error: "Not logged in Salesforce" });
    }

    try {
        const query = `
            SELECT Id, Name, Course_Name__c, Due_Date__c,
                   Amount__c, Status__c
            FROM Fee__c
        `;

        const response = await fetch(
            `${salesforceAuth.instanceUrl}/services/data/v59.0/query?q=${encodeURIComponent(query)}`,
            {
                headers: {
                    Authorization: `Bearer ${salesforceAuth.accessToken}`,
                },
            }
        );

        const data = await response.json();

        const formatted = data.records.map(r => ({
            id: r.Name,
            sfId: r.Id,
            courseName: r.Course_Name__c,
            dueDate: r.Due_Date__c,
            amount: r.Amount__c,
            status: r.Status__c,
        }));

        res.json(formatted);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: "Failed to fetch fees" });
    }
});

app.post("/api/pay/:id", async (req, res) => {
    const recordId = req.params.id;

    if (!salesforceAuth.accessToken) {
        return res.status(401).json({ error: "Not logged in Salesforce" });
    }

    try {
        const response = await fetch(
            `${salesforceAuth.instanceUrl}/services/data/v59.0/sobjects/Fee__c/${recordId}`,
            {
                method: "PATCH",
                headers: {
                    Authorization: `Bearer ${salesforceAuth.accessToken}`,
                    "Content-Type": "application/json",
                },
                body: JSON.stringify({
                    Status__c: "Paid",
                }),
            }
        );

        if (!response.ok) {
            const err = await response.text();
            return res.status(400).json({ error: err });
        }

        res.json({ success: true });

    } catch (err) {
        console.error(err);
        res.status(500).json({ error: "Payment failed" });
    }
});

// Test backend
app.get("/", (req, res) => {
    res.send("Salesforce Backend is running");
});

// STEP 1: Redirect user to Salesforce Login

// app.get("/oauth/login", (req, res) => {
//     const authUrl =
//         `${process.env.SF_LOGIN_URL}/services/oauth2/authorize` +
//         `?response_type=code` +
//         `&client_id=${process.env.SF_CLIENT_ID}` +
//         `&redirect_uri=${encodeURIComponent(process.env.SF_REDIRECT_URI)}`;

//     res.redirect(authUrl);
// });
app.get("/oauth/login", (req, res) => {
    const loginUrl =
        `${process.env.SF_LOGIN_URL}/services/oauth2/authorize` +
        `?response_type=code` +
        `&client_id=${process.env.SF_CLIENT_ID}` +
        `&redirect_uri=${process.env.SF_REDIRECT_URI}`;

    res.redirect(loginUrl);
});

// STEP 2: Salesforce callback

import axios from "axios";

app.get("/oauth/callback", async (req, res) => {
    const code = req.query.code;

    try {
        const response = await axios.post(
            `${process.env.SF_LOGIN_URL}/services/oauth2/token`,
            new URLSearchParams({
                grant_type: "authorization_code",
                client_id: process.env.SF_CLIENT_ID,
                client_secret: process.env.SF_CLIENT_SECRET,
                redirect_uri: process.env.SF_REDIRECT_URI,
                code: code,
            }),
            {
                headers: { "Content-Type": "application/x-www-form-urlencoded" },
            }
        );

        // LƯU TOKEN VÀO BIẾN GLOBAL
        salesforceAuth.accessToken = response.data.access_token;
        salesforceAuth.instanceUrl = response.data.instance_url;

        res.send("Login successful. You can close this tab.");

    } catch (error) {
        res.status(500).json(error.response?.data || error.message);
    }
});

app.get("/api/me", async (req, res) => {
    const accessToken = req.query.token;
    const instanceUrl = req.query.instance;

    try {
        const response = await axios.get(
            `${instanceUrl}/services/data/v59.0/sobjects/User`,
            {
                headers: {
                    Authorization: `Bearer ${accessToken}`,
                },
            }
        );

        res.json(response.data);
    } catch (error) {
        res.status(500).json(error.response?.data || error.message);
    }
});

app.get("/api/query", async (req, res) => {
    try {
        const response = await axios.get(
            `${salesforceAuth.instanceUrl}/services/data/v59.0/query`,
            {
                headers: {
                    Authorization: `Bearer ${salesforceAuth.accessToken}`,
                },
                params: {
                    q: "SELECT Id, Name, Email FROM User LIMIT 5",
                },
            }
        );

        res.json(response.data);
    } catch (error) {
        res.status(500).json(error.response?.data || error.message);
    }
});

app.listen(PORT, () => {
    console.log(`Backend running at http://localhost:${PORT}`);
});