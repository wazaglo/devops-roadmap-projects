require("dotenv").config();

const express = require("express");
const basicAuth = require("express-basic-auth");

const app = express();
const PORT = process.env.PORT || 3000;

const USERNAME = process.env.USERNAME;
const PASSWORD = process.env.PASSWORD;
const SECRET_MESSAGE = process.env.SECRET_MESSAGE;

app.get("/", (req, res) => {
  res.send("Hello, world!");
});

app.get(
  "/secret",
  basicAuth({
    users: { [USERNAME]: PASSWORD },
    challenge: true,
    realm: "Secret Area",
  }),
  (req, res) => {
    res.send(SECRET_MESSAGE);
  }
);

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
