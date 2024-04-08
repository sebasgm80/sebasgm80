import { getUser } from "../../global/state/globalState";
import { changeColorRGB } from "../../utils";
import { initControler } from "../../utils/route";
import "./Header.css";

//!-------------------------------------------------------------------
//? ------------------1) TEMPLATE ------------------------------------
//!-------------------------------------------------------------------

const template = () => `
  <img
    src="https://res.cloudinary.com/dq186ej4c/image/upload/v1682679162/header_giqdug.jpg"
    alt="title hub game website (app)"
    class="logo"
  />
  <nav>
    <img
      src="https://res.cloudinary.com/dq186ej4c/image/upload/v1682684561/changeColor_tat29q.png"
      alt=" change to style mode page"
      id="changeColor"
    />
    <img
      src="https://res.cloudinary.com/dq186ej4c/image/upload/v1682685633/home_nekvs0.png"
      alt=" navigate to home app"         
      id="buttonDashboard"
    />
    <img
      src="https://res.cloudinary.com/dq186ej4c/image/upload/v1682679055/logout_arz0gw.png"
      alt="logout"
      id="buttonLogout"
    />
  </nav>
`;
//!-----------------------------------------------------------------------------------
//? ----------------------- 2 ) Añadir los eventos con sus escuchadores---------------
//!-----------------------------------------------------------------------------------
const addListeners = () => {
  /** Para cada elemento grafico que son los botones que hacen acciones con el usuario
   * le meteremos su escuchador
   */
  //! ---------------->COLOR CHANGE RANDOM------ evento click del boton de cambio de color
  const changeColor = document.getElementById("changeColor");
  changeColor.addEventListener("click", (e) => {
    /** en este caso lo que hacemos el generar un color y cambiar el stylo del background del body */
    const color = changeColorRGB();
    document.body.style.background = color;
  });

  //! ----------------> DASHBOARD ------------- evento click del boton que nos lleva a los juegos
  const buttonDashboard = document.getElementById("buttonDashboard");
  buttonDashboard.addEventListener("click", (e) => {
    // llamamos al initController con el dashboard para que pinte la pagina del dashboard
    initControler("Dashboard");
  });

  //! ----------------> LOGOUT ----------------
  const buttonLogout = document.getElementById("buttonLogout");
  buttonLogout.addEventListener("click", (e) => {
    /** Ahora vamos a empezar a utilizar los estados con sus funciones get y set
     * En este caso primero vamos a traernos el nombre del usuario que esta logado y
     * que se encuentra en el sessionStorage
     * Esto lo hacemos porque es el nombre con el que podemos traer los datos del localStorage
     * Al traernos los datos del localStorage vamos a modificar el objeto y poner el token a false
     * porque es el token lo que nos da el ok o no en nuestra aplicacion
     *
     * Es una simulacion para luego cuando estemos en el back nos sea mucho mas sencillo entender que
     * para las request al back que necesiten autenticacion necesitaremos un token valido.
     */
    const userState = getUser().name;
    const currentUser = localStorage.getItem(userState);
    const parseCurrentUser = JSON.parse(currentUser);
    const updateUser = { ...parseCurrentUser, token: false };
    const stringUpdateUser = JSON.stringify(updateUser);
    localStorage.removeItem(userState);
    sessionStorage.removeItem("currentUser");
    localStorage.setItem(userState, stringUpdateUser);

    /** una vez borrado el currentUser del sessionStorage llamamos al initControler para que renderice el
     * login, aunque si no le hubieramos puesto ningun parametro hubiera hecho la misma accion porque
     * evalua si tenermos currentUser en el sessionStorage
     *
     */
    initControler("Login");
  });
};
//!-----------------------------------------------------------------------------------
//? ------------------------------ 3) La funcion que se exporta y que pinta-----------
//!-----------------------------------------------------------------------------------
export const PrintTemplateHeader = () => {
  document.querySelector("header").innerHTML = template();
  addListeners();
};
