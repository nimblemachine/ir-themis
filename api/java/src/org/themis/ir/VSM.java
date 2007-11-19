package org.themis.ir;

import java.sql.SQLException;

public class VSM extends Model
{
	public VSM(String host, String name, String user, String pwd) throws SQLException, ClassNotFoundException
	{
		super("vsm", host, name, user, pwd);
	}
}
