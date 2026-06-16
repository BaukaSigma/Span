const fs = require("fs");
const path = require("path");
const crypto = require("crypto");
const cloudinary = require("../config/cloudinary");

const uploadBuffer = async (buffer, options = {}) => {
  // Check if Cloudinary credentials are fully configured
  if (
    process.env.CLOUDINARY_CLOUD_NAME &&
    process.env.CLOUDINARY_API_KEY &&
    process.env.CLOUDINARY_API_SECRET
  ) {
    return new Promise((resolve, reject) => {
      const stream = cloudinary.uploader.upload_stream(
        options,
        (error, result) => {
          if (error) return reject(error);
          resolve(result);
        }
      );
      stream.end(buffer);
    });
  }

  // Fallback: Save file locally under public uploads folder
  console.log("⚠️ [cloudinaryUpload] Cloudinary not configured. Falling back to local storage.");
  
  const uploadsDir = path.join(__dirname, "../uploads");
  if (!fs.existsSync(uploadsDir)) {
    fs.mkdirSync(uploadsDir, { recursive: true });
  }

  const ext = options.originalname 
    ? path.extname(options.originalname) 
    : (options.resource_type === "raw" ? ".bin" : ".jpg");
  const filename = `${crypto.randomBytes(16).toString("hex")}${ext}`;
  const filePath = path.join(uploadsDir, filename);

  await fs.promises.writeFile(filePath, buffer);

  const appUrl = process.env.APP_URL || "http://localhost:5000";
  const fileUrl = `${appUrl}/uploads/${filename}`;

  return {
    secure_url: fileUrl,
    public_id: filename,
  };
};

module.exports = { uploadBuffer };

