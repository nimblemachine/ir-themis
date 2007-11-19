package org.themis.ir;

import java.sql.SQLException;

public class eTVSM extends Model
{
	public eTVSM(String host, String name, String user, String pwd) throws SQLException, ClassNotFoundException
	{
		super("etvsm", host, name, user, pwd);
	}
}
