/** --------CONTEXTO CON LOS ESTADOS DE LA APLICACION QUE SON COMUNES-------
 * ----------------A TODOS SU COMPONENTES Y PAGINAS---------------------- */

/** En una aplicacion hay siempre un contexto donde se guardan los diferentes estados
 * de una aplicacion. Que es un estado ?? es donde se guarda info con una situacion concreta
 * en ese momento dado. Por ejemplo: dataPokemon puede ser un objeto donde un estado inicial esta
 * vacia de contenido y en un estado 1 se encuentra con todos los datos que ha recibido de la API mediante
 * una llamada asincrona
 *
 * Quien controla los estados?
 * Dos funciones: una GET  y otra SET
 * 1) -----> La funcion get se encarga de dar el valor de ese estado en ese momento por lo que  lo
 * unico que hara es retornar el valor de ese estado(que normalmente es un objeto)
 * 2) -----> La funcion set que se encarga de settear los valores de los estados es decir actualiza
 * su valor por lo cual es una funcion que recibe un parametro con unos valores y esa info la iguala al
 * estado el cual modifica
 */

//! -----------------------------------------------------------------------------------
//?-----------------> INICIALIZACION EN LAZY DEL ESTADO ----------------
//! -----------------------------------------------------------------------------------

/** Siempre lo primero que se hace es crear los estados y le damos su valor
 *  inicial antes de modificarlos */

/* este estado de currrentUser es el usuario que se encuenta actualmente logado en la aplicacion
tiene una inicializacion en lazy. Esto quiere decir que mira si tenemos algun valor en le local storage 
si tenemos un valor lo vamos asignar al valor de currentUser sino será un string vacio


ESTO SE HACE PORQUE SI RECARGO LA PAGINA LOS ESTADOS VUELVEN A SU VALOR INCIAL, si no tubieramos esto
si recargo sería "" STRING vacio por lo cual cuando recargo en este caso lo que hace es valorar si en
el sessionStorage existe currentUser y se existir lo setea en este objeto
 */
const currentUser = {
  name: sessionStorage.getItem("currentUser")
    ? sessionStorage.getItem("currentUser")
    : "",
};

/*------------------> este estado se encarga de incluir los datos de user con sus favoritos y es
practicamente igual que lo que se settea en el local storage para guardar sus favoritos
 */

let userData = localStorage.getItem(currentUser.name)
  ? JSON.parse(localStorage.getItem(currentUser.name))
  : {
      name: "",
      token: false,
      fav: [],
    };

// ------------------> DATA GLOBAL DE LA APLICACION--------
/**En este caso es donde se van a guardar los datos que vengan de las API y que vamos a utilizarlos en
 * los diferentes apartados de la app: por ejemplo si tuvieramos dos paginas una de pokemon y otra de ricky
 * morty en este caso en cada clave guardariamos el valor de los datos de cada página.
 */
const dataGlobal = {
  pokemon: [],
  ricky: [],
};

//! --------------------------------------------------------------------------------------------
//? ----------------------------- FUNCIONES GET Y FUNCIONES SET---------------------------------
//! --------------------------------------------------------------------------------------------

/** Los estados como dijimos antes se utilizan mediante las funciones set y get:
 * - Las funciones GET: nos darian el valor actual que tiene el estado
 * . Las funciones SET: setean el valor que recibe como parametro en el estado que modifica
 */

//! -------------------- SET Y GET  currentUser ----------------

export const setUser = (username) => {
  currentUser.name = username;
};

export const getUser = () => {
  return currentUser;
};

//! -------------------- SET y GET dataGlobal----------------

export const setData = (data, page) => {
  switch (page) {
    case "Pokemon":
      dataGlobal.pokemon = data;

      break;

    default:
      break;
  }
};

export const getData = (page) => {
  switch (page) {
    case "Pokemon":
      return dataGlobal.pokemon;
    default:
      break;
  }
  return dataGlobal;
};

//! -------------------SET y GET  dde userData  --------------------------

export const setUserData = (data) => {
  console.log(".....metiendo datos en el contexto");
  userData.fav = data?.fav;
  userData.name = data?.name;
  userData.token = data?.token;
  /**En este caso no solo setea sino que tambien lo modifica en el localStorage
   * Como se ve lo mete con una forma especial para que en caso de corresponder
   * el nombre que introduce en el login con el que hay en el localStorage se pueda
   * recuperar los datos de los favoritos.
   */
  const stringUser = JSON.stringify(userData);
  localStorage.removeItem(`${currentUser.name}`);
  console.log(userData.name);
  localStorage.setItem(`${currentUser.name}`, stringUser);
};

export const getUserData = () => {
  return userData;
};
