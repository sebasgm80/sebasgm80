import {
  PrintTemplateSpinner,
  CardsPokemons,
  PrintButton,
  PrintSpinner,
} from "../../components";
import { getData } from "../../global/state/globalState";
import { Paginacion, filterPokemon } from "../../utils";
import "./Pokemon.css";

//! ------------------------------------------------------------------------------
//? ------------------------------TEMPLATE INICIAL--------------------------------
//! ------------------------------------------------------------------------------
const template = () => `
  <div id="pokemon">
    <div id="containerFilter">
      <div id="spinnerButtonFilter"></div>
      <div id="filterButton"></div>
      <input
        type="text"
        id="inputPokemon"
        placeholder="Busca tu pokemon favorito"
      />
    </div>
    <div id="paginacion"></div>
    <div id="spinner"></div>
    <div id="galleryPokemon"></div>
  </div>
`;

//! ------------------------------------------------------------------------------
//? ----------------- FUNCION QUE TRAE LOS DATOS DEL CONTEXTO--------------------
//! ------------------------------------------------------------------------------
const dataService = async () => {
  /** Nos traemos los datos de los pokemons pero antes pintamos el spinner en el PrintPokemonPage
   * esto es porque antes de que esten los datos en caso de no tenelos que se pinten los spinner de carga
   *
   *
   * Una vez los tenemos hacemos destructuring de pokemonData y los type (LOS TIPOS)
   */
  const getDataPokemon = getData("Pokemon");

  const { pokemonData, type } = getDataPokemon;

  /**borramos los spinner porque ya tenemos los datos y una vez los hemos borrado mandamos a pintar los botones
   * y borramos despues su spinner
   */
  document.getElementById("spinner").innerHTML = "";
  PrintButton(type);
  document.getElementById("spinnerButtonFilter").innerHTML = "";

  /** Una vez hemos pintado todo le inyectamos al input sus escuchadores y mandamos a paginacion a pintar los
   * 25 primeros elementos
   */
  addListeners();
  Paginacion(pokemonData, 25);
};

//! ------------------------------------------------------------------------------
//? ---------------------------EVENTOS PARA EL INPUT-----------------------------------
//! ------------------------------------------------------------------------------
const addListeners = () => {
  // EVENT TO INPUT

  const inputPokemon = document.getElementById("inputPokemon");
  inputPokemon.addEventListener("input", (e) => {
    /** este evento lo unico que hace es mandar el valor del input y el tipo de filtro que tiene que
     * hacer a la funcion que se encarga de filtrar.
     *
     * Recordar este funcion nos sirve gracias al switch para el filtrado por name como para el filtrado por
     * button con los tipos de pokemons
     */
    filterPokemon(e.target.value, "name");
  });
};

//! ------------------------------------------------------------------------------
//? ---------------------FUNCION QUE SE EXPORTA QUE PINTA LA PAGINA--------------
//! ------------------------------------------------------------------------------
export const PrintPokemonPage = () => {
  document.querySelector("main").innerHTML = template();

  /** primero pintamos los spinner y luego llamamos a la funcion de dataService que trae los datos de las funciones
   * que se encargan dee gestionar la asincronia y de procesar los datos
   */
  PrintTemplateSpinner();
  PrintSpinner();
  dataService();
};
