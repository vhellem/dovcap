import React from 'react';
import { Link } from 'react-router';

const Navigation = () => (
    <ul className="landing-page-navigation">
      <div className="nav-inner">
        <li className="nav-item nav-brand">
          <Link className="nav-link" to="/">
            DOVCAP
          </Link>
        </li>
        <li className="nav-item">
          <Link className="nav-link" to="/workplace">
            Workplace
          </Link>
        </li>
        <li className="nav-item">
          <Link className="nav-link" to="/upload">
            Upload
          </Link>
        </li>
      </div>
    </ul>
);
export default Navigation;
