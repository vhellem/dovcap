import React from 'react';
import {getModelsFromBackend} from './utlities.js';


class App extends React.Component {


    componentWillMount() {
        getModelsFromBackend().then(res => {

            const json = JSON.parse(res.text); 

            console.log(json) ;
        })

    }
    render() {

        return (
            <h1>React app</h1>
        )
    }


}



export default App