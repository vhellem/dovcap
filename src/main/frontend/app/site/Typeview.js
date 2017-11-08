import React from 'react';

class TypeView extends React.Component {
  constructor(props) {
    super(props);
  }

  getTypes(data) {
    var html = "<ul>";
    var unique = [...new Set(data.map(item => item.type))];
    for (var d of unique) {
      if (d==="Container") continue;
      html += "<li><span>"+d+"</span><i class='fa fa-eye'></i></li>";
    }
    html += "<li><span>Relation</span><i class='fa fa-eye'></i></li>";
    html += "</ul>";
    return html;
  }

  render() {
    console.log("open", this.props.fullData);
    var html = this.getTypes(this.props.fullData.viewL);
    console.log("final", html);


    return (
      <div className="dialog" style={{ width: this.props.width, height: this.props.height }}>
        <div className="close">
          <i className="fa fa-times" onClick={() => this.props.toggle("TypeView")}></i>
        </div>
        <div className="content tree">
          <div dangerouslySetInnerHTML={{ __html: html }} />
        </div>
      </div>
    )
  }
}


export default TypeView;
