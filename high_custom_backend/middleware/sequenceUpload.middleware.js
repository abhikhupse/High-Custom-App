const upload = require("./upload.middleware");

const sequenceUpload = upload.fields([
  {
    name: "brandLogo",
    maxCount: 1,
  },
  {
    name: "heroImage",
    maxCount: 1,
  },
  {
    name: "attachment",
    maxCount: 1,
  },
]);

module.exports = sequenceUpload;
