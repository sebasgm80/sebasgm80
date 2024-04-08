import { CardsPokemons } from "../components";

export const Paginacion = (data, numberElement) => {
  /**
   * PARAMETROS:
   * 1) ---> La data total a paginar
   * 2) ---> Los elementos que queremos por cada pagina
   */

  /** Vamos a calcular la longitud del array total para dividirlo entre el numero de elementos
   * para asi saber el numero de paginas vamos a necesitar
   */
  const longitud = data.length;
  const numberDigitOfPage = longitud / numberElement;

  /** El contenedor de paginacion que pinto la pagina de pokemon lo vamos a borrar para
   * pintar la paginacion nueva
   */
  document.getElementById("paginacion").innerHTML = "";

  /** Pero hay que ponerle una condicion y es que si el numero de paginas que se guarda en la
   * variable numberDigitOfPage es menor 1 o menor no se va rendirizar paginado sino normal
   * Solo cuando es mayor que 1 se va a paginar
   */
  if (numberDigitOfPage > 1) {
    /** Si el numero de paginas es mayor que 1 lo que vamos a hacer es crear un botton por
     * cada pagina y le añadimos una clase con el i del bucle mas 1 , y tambien buttonPaginacion
     * para asi luego poder darle estilos a la pagina en la que nos encontramos actualmente
     * que lo veremos en el escuchador de estos botones como modificamos estos estilos
     */
    for (let i = 0; i < numberDigitOfPage; i++) {
      const buttonNumber = document.createElement("button");
      buttonNumber.setAttribute("class", `${i + 1} buttonPaginacion`);
      buttonNumber.innerHTML = i + 1;

      //al contenedor paginacion le metemos como hijo cada uno de los botones con las paginas
      document.getElementById("paginacion").appendChild(buttonNumber);

      // le metemos los escuchadores
      addListeners(buttonNumber, data, numberElement, i);
    }

    /** Antes de salir de la funcion que crea los botones les vamos a dar los estilos y marcar el primer
     * elemento de todos los botones encontrados con el querySelectorAll con un estilo especial para
     * que se sepa que incialmente lo que renderizamos es el boton numero 1 que corresponde con la pagina 1
     * Recordar que aunque sea el boton de la pagina 1 en el querySelectorAll es la posion 0
     */
    const allButton = document.querySelectorAll(".buttonPaginacion");
    allButton.forEach((pag) => {
      pag.style.border = "solid 3px #0000006d ";
    });
    allButton[0].style.border = "solid 3px #15a00e7d";
    allButton[0].style.color = " #083905ff";
  }

  /** Como renderizamos la primera pagina vamos a hacer un corte del array con los primeros elementos de
   * la primera pagina y se lo mandamos al componente de la carta de pokemon
   */
  CardsPokemons(data.slice(0, numberElement));
};

//! -----------------------------------------------------------------------------------------
//? -----------------ESCUCHHADORES DE LOS EVENTOS DE LOS BOTONES DE LAS PAGINAS--------------
//! ------------------------------------------------------------------------------------------
const addListeners = (buttonNumber, data, numberElement, i) => {
  /**
   * PARAMETROS:
   * 1)buttonNumber: el botton que acaba de crear al cual vamos a darle el event porque crea el botton
   *                y seguidamente le mete el evento
   * 2)data: son todos los elementos de el total de los datos que se quiere pintar
   * 3)numberElement: son los numero de elementos que queremos pintar por pagina
   * 4)i: es el indice del bucle que se encarga de crear todos los botones de las paginas
   */
  buttonNumber.addEventListener("click", () => {
    console.log("entro");

    /** Lo que va a hacer es apuntar a todos los botones que estan pintados y les va a dar un estilo comun
     * y luego al boton en el que estamos pinchando le va a dar otro color. En este caso el boton al que
     * estamos pinchando es al que corresponde el evento por lo cual es la variable que se le añade el escuchador
     * en nuestro caso llamada la variable buttonNumber
     */
    const allButtonPag = document.querySelectorAll(".buttonPaginacion");

    allButtonPag.forEach((pag) => {
      pag.style.border = "solid 3px #0000006d ";
    });

    buttonNumber.style.border = "solid 3px #15a00e7d ";
    buttonNumber.style.color = " #093f06ff";

    /** Ahora debemos saber cuales son los elementos que tenemos que renderizar en CardPokemos
     * Tenemos que saber el princio y el final de donde tenemos que hacer el slice
     * para el final es facil porque es el indice del bucle al que corresponde este boton mas un 1 y esto multiplicado por el numero de elementos
     * Por lo que si es el button del indice 0 corresponde al boton 1 y si le decimos que renderice 3
     * elementos por pagina en este caso es 0 +1 = 1 y luego lo multiplicas por el numero de elementos
     * por pagina que son 3 por lo cual 1 * 3 = el final estaria en la posicion 3 del border-image-slice:
     *
     *
     * Ahora vamos con lo complicado que el incio
     * Para el incio hay que hacer un ternario porque nunca va a tener un array una posicion por debajo de 0
     * por lo cual si el final menos el numero de elementos por pagina es menor que 0 en este caso el incio del corte sera 0
     * si es mayor que cero sera el resultado de esa operacion es ddecir: final menos el numero de elementos
     *
     * por cual ejemplos:
     * pagina 1:
     * --> End = (0 +1) * 3 =====> 3
     * --> start = 3 - 3 ===> esto es 0 por lo cual star = 0
     * El slice se hario slice(0, 3)------> cogeria las posiciones 0,1,2 ---> los tres elementos le indicamos por pagina
     */
    const end = (i + 1) * numberElement;
    const start = end - numberElement < 0 ? 0 : end - numberElement;

    /** Una vez calculado el slice se lo pasamos al componente CardsPokemons que se encarga de pintar la galeria pokemon */
    CardsPokemons(data.slice(start, end));
  });
};
