/**
    Themis - Information Retrieval framework
    Copyright (C) 2007 Artem Polyvyanyy

    This file is part of Themis.
	
    Themis is free software: you can redistribute it and/or modify
    it under the terms of the GNU Lesser General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Themis is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>
 */
package org.themis.ir.etvsm;

import java.sql.SQLException;

import org.themis.ir.Model;
import org.themis.util.IRMODEL;

public class eTVSM extends Model
{
	public eTVSM(String host, String name, String user, String pwd) throws SQLException, ClassNotFoundException
	{
		super(IRMODEL.eTVSM.toString(), host, name, user, pwd);
	}
}
