const nodemailer = require("nodemailer");

const sendBookingEmail = async ({
  clientName,
  clientPhone,
  trainerName,
  trainingDate,
  slot,
  comment,
}) => {
  const dateStr = new Date(trainingDate).toLocaleDateString("ru-RU");

  const subject = `Новая запись на тренировку - ${dateStr} (${slot})`;
  const textContent = `
Здравствуйте, ${trainerName}!

К вам записался новый ученик на тренировку:
- Ученик: ${clientName}
- Телефон: ${clientPhone}
- Дата: ${dateStr}
- Время (слот): ${slot}
${comment ? `- Комментарий: ${comment}` : ""}

С уважением,
Команда ORTUS Martial Arts
  `;

  // Check if SMTP is configured
  if (
    process.env.SMTP_HOST &&
    process.env.SMTP_PORT &&
    process.env.SMTP_USER &&
    process.env.SMTP_PASS
  ) {
    try {
      const transporter = nodemailer.createTransport({
        host: process.env.SMTP_HOST,
        port: parseInt(process.env.SMTP_PORT, 10),
        secure: parseInt(process.env.SMTP_PORT, 10) === 465, // true for 465, false for other ports
        auth: {
          user: process.env.SMTP_USER,
          pass: process.env.SMTP_PASS,
        },
      });

      await transporter.sendMail({
        from: process.env.SMTP_FROM || `"ORTUS Martial Arts" <${process.env.SMTP_USER}>`,
        to: process.env.SMTP_FROM, // For testing, send to admin/from address or configure target
        subject,
        text: textContent,
      });

      console.log(`✉️ Email notification sent successfully to ${process.env.SMTP_FROM}`);
    } catch (error) {
      console.error("❌ Failed to send email via SMTP:", error.message);
    }
  } else {
    console.log("--------------------------------------------------");
    console.log("✉️ [MOCK EMAIL] SMTP not configured. Printing email content to terminal:");
    console.log(`Тема: ${subject}`);
    console.log(textContent);
    console.log("--------------------------------------------------");
  }
};

module.exports = { sendBookingEmail };
