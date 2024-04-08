export const typePokemon = (data) => {
  /** esta es una funcion para sacar en un array todos los nombre
   * de los tipos de los pokemons
   * para esto lo que hace es recorrer
   * el parametro que recibe con todos los pokemons y  tiene que hacer
   * dos bucles porque recordar que los tipos
   * pueden ser dos por lo cual primero recorre el de
   * los pokemon y dentro del bucle
   * hace otro bucle con el array de tipos y
   * ahi entonces es donde hace la condicion de: si
   * el name del tipo del pokemon no esta
   * incluido en el array con los nombres sin repetir,
   * lo mete entonces con un push a ese array que no lo contiene ,
   * si esta incluido, no lo mete
   */
  const nameType = [];
  data.forEach((element) => {
    element.type.forEach((singleType) => {
      !nameType.includes(singleType.type.name) &&
        nameType.push(singleType.type.name);
    });
  });

  return nameType;
};
