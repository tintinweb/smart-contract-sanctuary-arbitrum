/**
 *Submitted for verification at Arbiscan on 2023-04-17
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

contract App {
    mapping(address => Cuenta) internal aplicacion;
    mapping(string => Hashtag) internal hashtags;
    mapping(string => address) internal nicknames;
    Post[] public posts;
    address[] public cuentas;
    Comentario[] public comentarios;
    string[] public clavesHashtags;

    struct Cuenta {
        string nombre;
        uint256[] keysPosts;
        uint256 keyCuenta;
        address[] cuentasSeguidas;
        string urlImagen;
        uint256[] keysPostsLikes;
        uint256[] keysPostsRetweets;
        string nickname;
        string[] ipfsdata;
    }

    struct Hashtag {
        string nombre;
        uint256[] keysPosts;
    }

    struct Post {
        address owner;
        uint256 id;
        uint256 likes;
        uint256 retweets;
        string mensaje;
        uint256[] keysComentarios;
    }

    struct Comentario {
        address autor;
        string mensaje;
    }

    function test() public view returns (address) {
        return cuentas[aplicacion[msg.sender].keyCuenta];
    }

    function existeNickname(
        string memory _nickname
    ) public view returns (bool) {
        return nicknames[_nickname] != address(0);
    }

    //Registro con nickname
    function crearNickname(string calldata _nickname) public {
        require(!existeNickname(_nickname), "El nickname ya existe");
        nicknames[_nickname] = msg.sender;
        aplicacion[msg.sender].nickname = _nickname;
        aplicacion[msg.sender].keyCuenta = cuentas.length;
        cuentas.push(msg.sender);
    }

    //Registro con nickname y +
    function crearNicknameNombreYUrl(
        string calldata _nickname,
        string calldata _nombre,
        string calldata _url
    ) public {
        require(!existeNickname(_nickname), "El nickname ya existe");
        nicknames[_nickname] = msg.sender;
        aplicacion[msg.sender].nickname = _nickname;
        aplicacion[msg.sender].nombre = _nombre;
        aplicacion[msg.sender].urlImagen = _url;
        aplicacion[msg.sender].keyCuenta = cuentas.length;
        cuentas.push(msg.sender);
    }

    function comprobarRegistro() public view returns (bool) {
        if (
            cuentas.length == 0 ||
            msg.sender != cuentas[aplicacion[msg.sender].keyCuenta]
        ) {
            return false;
        }
        return true;
    }

    function modificarNombreYUrl(
        string calldata _nombre,
        string calldata _url
    ) public {
        aplicacion[msg.sender].nombre = _nombre;
        aplicacion[msg.sender].urlImagen = _url;
    }

    function getCuenta(
        address _cuenta
    )
        public
        view
        returns (
            string memory,
            uint256[] memory,
            uint256,
            address[] memory,
            string memory,
            string memory,
            string[] memory
        )
    {
        Cuenta memory cuenta = aplicacion[_cuenta];
        return (
            cuenta.nombre,
            cuenta.keysPosts,
            cuenta.keyCuenta,
            cuenta.cuentasSeguidas,
            cuenta.urlImagen,
            cuenta.nickname,
            cuenta.ipfsdata
        );
    }

    function getCuentaPropia()
        public
        view
        returns (
            string memory,
            uint256[] memory,
            uint256,
            address[] memory,
            string memory,
            string memory,
            string[] memory
        )
    {
        Cuenta memory infcuenta = aplicacion[msg.sender];
        return (
            infcuenta.nombre,
            infcuenta.keysPosts,
            infcuenta.keyCuenta,
            infcuenta.cuentasSeguidas,
            infcuenta.urlImagen,
            infcuenta.nickname,
            infcuenta.ipfsdata
        );
    }

    function saveIpfsData(string calldata _cid) public {
        aplicacion[msg.sender].ipfsdata.push(_cid);
    }

    function eraseIpfsDataIndex(uint256 _index) public {
        Cuenta storage user = aplicacion[msg.sender];

        require(_index < user.ipfsdata.length, "Indice fuera de rango");

        for (uint256 i = _index; i < user.ipfsdata.length - 1; i++) {
            user.ipfsdata[i] = user.ipfsdata[i + 1];
        }
        user.ipfsdata.pop();
    }

    function getOwnIpfsData() public view returns (string[] memory) {
        return aplicacion[msg.sender].ipfsdata;
    }

    function getPostsTotales(address _cuenta) public view returns (uint256) {
        return aplicacion[_cuenta].keysPosts.length;
    }

    function getPostsCuenta(
        address _cuenta
    ) public view returns (Post[] memory) {
        Post[] memory postEnviados = new Post[](getPostsTotales(_cuenta));
        for (uint256 i = 0; i < getPostsTotales(_cuenta); i++) {
            postEnviados[i] = posts[aplicacion[_cuenta].keysPosts[i]];
        }
        return postEnviados;
    }

    function getPostsCuentaNickname(
        string calldata _nickname
    ) public view returns (Post[] memory) {
        Post[] memory postEnviados = new Post[](
            aplicacion[nicknames[_nickname]].keysPosts.length
        );
        for (
            uint256 i = 0;
            i < aplicacion[nicknames[_nickname]].keysPosts.length;
            i++
        ) {
            postEnviados[i] = posts[
                aplicacion[nicknames[_nickname]].keysPosts[i]
            ];
        }
        return postEnviados;
    }

    function esSeguida(address _cuentaASeguir) public view returns (bool) {
        if (_cuentaASeguir == msg.sender) {
            return true;
        }
        Cuenta memory cuenta = aplicacion[msg.sender];
        for (uint256 i = 0; i < cuenta.cuentasSeguidas.length; i++) {
            if (_cuentaASeguir == cuenta.cuentasSeguidas[i]) {
                return true;
            }
        }
        return false;
    }

    function seguirCuenta(address _cuenta) public {
        require(!esSeguida(_cuenta), "Error: Cuenta ya seguida o propia");
        aplicacion[msg.sender].cuentasSeguidas.push(_cuenta);
    }

    function getArraysCuentasYCuentasSeguidas()
        public
        view
        returns (address[] memory, address[] memory)
    {
        return (cuentas, aplicacion[msg.sender].cuentasSeguidas);
    }

    function existeHashtag(
        string calldata _hashtag
    ) public view returns (bool) {
        bytes32 hash1 = keccak256(bytes(_hashtag));
        bytes32 hash2 = keccak256(bytes(hashtags[_hashtag].nombre));
        return hash1 == hash2;
    }

    function crearPostYHashtag(
        string calldata _mensaje,
        string calldata _hashtag
    ) public {
        if (existeHashtag(_hashtag)) {
            hashtags[_hashtag].keysPosts.push(posts.length);
        } else {
            hashtags[_hashtag].nombre = _hashtag;
            hashtags[_hashtag].keysPosts.push(posts.length);
            clavesHashtags.push(_hashtag);
        }

        aplicacion[msg.sender].keysPosts.push(posts.length);
        Post memory p;
        p.owner = msg.sender;
        p.id = posts.length;
        p.mensaje = _mensaje;
        posts.push(p);
    }

    function getPostsHashtag(
        string calldata _hashtag
    ) public view returns (Post[] memory) {
        Post[] memory postHashtag = new Post[](
            hashtags[_hashtag].keysPosts.length
        );
        for (uint256 i = 0; i < hashtags[_hashtag].keysPosts.length; i++) {
            postHashtag[i] = posts[hashtags[_hashtag].keysPosts[i]];
        }
        return postHashtag;
    }

    function crearPost(string calldata _mensaje) public {
        aplicacion[msg.sender].keysPosts.push(posts.length);
        Post memory p;
        p.owner = msg.sender;
        p.id = posts.length;
        p.mensaje = _mensaje;
        posts.push(p);
    }

    function crearComentario(string calldata _mensaje, uint256 _idPost) public {
        posts[_idPost].keysComentarios.push(comentarios.length);
        //aplicacion[msg.sender].keysPosts.push(posts.length);
        Comentario memory p;
        p.autor = msg.sender;
        p.mensaje = _mensaje;
        comentarios.push(p);
        //cantidadMensajes[msg.sender]+=1;
    }

    function getNombresCuentas(
        address[] calldata _cuentas
    ) public view returns (string[] memory) {
        string[] memory nombresCuentas = new string[](_cuentas.length);
        for (uint256 i = 0; i < _cuentas.length; i++) {
            nombresCuentas[i] = aplicacion[_cuentas[i]].nombre;
        }
        return nombresCuentas;
    }

    function getComentariosPost(
        uint256 _idPost
    ) public view returns (Comentario[] memory) {
        Comentario[] memory comentariosPost = new Comentario[](
            getComentariosTotales(_idPost)
        );
        for (uint256 i = 0; i < getComentariosTotales(_idPost); i++) {
            comentariosPost[i] = comentarios[posts[_idPost].keysComentarios[i]];
        }
        return comentariosPost;
    }

    function getComentariosTotales(
        uint256 _idPost
    ) public view returns (uint256) {
        return posts[_idPost].keysComentarios.length;
    }

    function tieneLike(uint256 _idPost) public view returns (bool) {
        for (
            uint256 i = 0;
            i < aplicacion[msg.sender].keysPostsLikes.length;
            i++
        ) {
            if (aplicacion[msg.sender].keysPostsLikes[i] == _idPost)
                return true;
        }
        return false;
    }

    function darLike(uint256 _idPost) public {
        require(!tieneLike(_idPost), "Error: Ya le has dado like");
        aplicacion[msg.sender].keysPostsLikes.push(_idPost);
        posts[_idPost].likes += 1;
    }

    function tieneRetweet(uint256 _idPost) public view returns (bool) {
        for (
            uint256 i = 0;
            i < aplicacion[msg.sender].keysPostsRetweets.length;
            i++
        ) {
            if (aplicacion[msg.sender].keysPostsRetweets[i] == _idPost)
                return true;
        }
        return false;
    }

    function darRetweet(uint256 _idPost) public {
        require(!tieneRetweet(_idPost), "Error: Ya le has dado like");
        aplicacion[msg.sender].keysPostsRetweets.push(_idPost);
        posts[_idPost].retweets += 1;
    }

    function getPostsMeGustaCuenta(
        address _cuenta
    ) public view returns (Post[] memory) {
        Post[] memory postMeGusta = new Post[](
            aplicacion[_cuenta].keysPostsLikes.length
        );
        for (
            uint256 i = 0;
            i < aplicacion[_cuenta].keysPostsLikes.length;
            i++
        ) {
            postMeGusta[i] = posts[aplicacion[_cuenta].keysPostsLikes[i]];
        }
        return postMeGusta;
    }

    function getPostsRetweetCuenta(
        address _cuenta
    ) public view returns (Post[] memory) {
        Post[] memory postRetweet = new Post[](
            aplicacion[_cuenta].keysPostsRetweets.length
        );
        for (
            uint256 i = 0;
            i < aplicacion[_cuenta].keysPostsRetweets.length;
            i++
        ) {
            postRetweet[i] = posts[aplicacion[_cuenta].keysPostsRetweets[i]];
        }
        return postRetweet;
    }
}