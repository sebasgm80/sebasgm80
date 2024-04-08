const express = require('express');
const dotenv = require('dotenv');
const nodemailer = require('nodemailer');
dotenv.config();

const PORT = process.env.PORT;

const app = express();

const router = express.Router();

router.get("/send", (req, res, next) => {

    const EMAIL = process.env.EMAIL;
    const PASSWORD = process.env.PASSWORD;
    //creamos funcion del servicio y auntetificacion

    const transporter = nodemailer.createTransport({
        service: 'gmail',
        auth: {
            user: EMAIL,
            pass: PASSWORD
        }
    });

    const mailOptions = {
        from: EMAIL,
        to: 'sebasgarcia80@gmail.com',
        subject: 'Mensaje de prueba todo bien',
        text: 'Hola que tal todo bien ?'
    };

    if (error) {
        console.error('Error al enviar el correo:', error);
        res.status(500).send('Error al enviar el correo');
    } else {
        console.log('Email enviado: ' + info.response);
        res.send('Email enviado: ' + info.response);
    }
    
    });
    


app.use("/email", router);

app.listen(PORT, () => {
    console.log(`Server running on port http://localhost:${PORT}`);
});



