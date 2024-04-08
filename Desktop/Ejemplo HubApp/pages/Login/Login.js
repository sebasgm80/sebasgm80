import { setUser, setUserData } from "../../global/state/globalState";
import { initControler } from "../../utils/route";
import "./Login.css";
const template = () => `
  <div id="containerLogin">
    <h1 id="titleLogin">LOGIN</h1>
    <input type="text" name="username" id="username" />
    <button id="buttonLogin">enviar</button>
  </div>
`;

const addListeners = () => {
  const buttonLogin = document.getElementById("buttonLogin");
  const username = document.getElementById("username");
  buttonLogin.addEventListener("click", (e) => {
    const valueInput = username.value;

    // como trabajo con el local lo convierto a string

    /**
     * Lo unico especial tiene este login es que comprueba si ya tenemos un usuario
     * en el local con datos dee algun usuario con el mismo nombre
     * y asi lo asocia para coger los me gusta de los pokemon
     */
    if (localStorage.getItem(`${valueInput}USER`)) {
      const localUser = localStorage.getItem(`${valueInput}USER`);
      const parseUser = JSON.parse(localUser);

      // importante es que si me logo es poner el token de autenticacion como true
      parseUser.token = true;

      const stringUser = JSON.stringify(parseUser);
      localStorage.setItem(`${valueInput}USER`, stringUser);
      sessionStorage.setItem("currentUser", `${valueInput}USER`);

      // y llamamos a la funcion dee set del user logado actual
      setUser(`${valueInput}USER`);
      // y seteamos los datos del locaStorage en los datos de usuario logado con sus favoritos
      setUserData(parseUser);
    } else {
      /** en caso de no estar este usuario de antes registrado en el localStorage lo que hacemos es que lo crearemos
       * de cero con su array de fav vacio y el token en true y el nombre es el nomvre del input
       */
      const customUser = {
        name: username.value,
        fav: [],
        token: true,
      };

      // lo metemos al localStorage añadiendole USER despues del nombre  y lo metemos al session como el currentUser de la app
      const stringUser = JSON.stringify(customUser);
      localStorage.setItem(`${valueInput}USER`, stringUser);
      sessionStorage.setItem("currentUser", `${valueInput}USER`);

      // seteamos el nombre en su estado asi como los datos del usaurio en el segundo estado customUser
      setUser(`${valueInput}USER`);
      setUserData(customUser);
    }

    /** llamamos al initControler sin el parametro para que compruebe que se ha metido el userCurrent en el sessionStorage  */
    initControler();
  });
};

export const Login = () => {
  /** cuando pintamos el login hay que ocultar la nav con sus navegaciones */
  document.querySelector("nav").style.display = "none";
  document.querySelector("main").innerHTML = template();
  addListeners();
};
