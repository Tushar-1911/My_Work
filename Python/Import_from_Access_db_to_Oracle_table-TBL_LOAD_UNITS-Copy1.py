{
 "cells": [
  {
   "cell_type": "markdown",
   "id": "3442497d",
   "metadata": {},
   "source": [
    "# IMPORT ACCESS DB TABLE TO ORACLE TABLE\n"
   ]
  },
  {
   "cell_type": "markdown",
   "id": "4290493d",
   "metadata": {},
   "source": [
    "CONNECTION TO ORACLE AND IMPORT REQUIRE LIBRARIES"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "id": "c706916f",
   "metadata": {},
   "outputs": [],
   "source": [
    "import pypyodbc\n",
    "import pandas as pd\n",
    "import cx_Oracle\n",
    "from cx_Oracle import DatabaseError\n",
    "dsn_tns = cx_Oracle.makedsn(' Hostname ', ' Port ', service_name=' Service Name ')\n",
    "con = cx_Oracle.connect(user='Username', password='Password', dsn=dsn_tns)\n",
    "\n",
    "# MS ACCESS DB CONNECTION\n",
    "pypyodbc.lowercase = False\n",
    "conn = pypyodbc.connect(\n",
    "r\"Driver={Microsoft Access Driver (*.mdb, *.accdb)};\" +\n",
    "r\"Dbq=W:\\PlanningAndMI\\MI\\040 DATABASE\\05. Transfer Files\\despatch\\DB05-DESPATCH-ARCHIVE-039.accdb;\")\n",
    "\n",
    "\n",
    "\n",
    "print(\"connected to oracle db!!!\")\n",
    "\n",
    "\n",
    "cursor = con.cursor()\n",
    "\n",
    "cursor.execute(\"\"\"ALTER SESSION SET NLS_DATE_FORMAT = 'DD-MM-YYYY HH24:MI:SS'\n",
    "                                    NLS_LANGUAGE = AMERICAN\"\"\")\n",
    "\n"
   ]
  },
  {
   "cell_type": "markdown",
   "id": "e6f494f2",
   "metadata": {},
   "source": [
    "IMPORT ACCESS TABLE INTO DATAFRAME"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "id": "3db6a3f7",
   "metadata": {},
   "outputs": [],
   "source": [
    "# OPEN CURSOR AND EXECUTE SQL and store data into pandas dataframe\n",
    "cur = conn.cursor()\n",
    "SQLCommand=\"SELECT * FROM stock_despatch_not_avl_picking_progress\"\n",
    "\n",
    "cur.execute(SQLCommand)\n",
    "df = cur.fetchall()\n",
    "df1= pd.DataFrame(df)\n",
    "df_p = df1.iloc[:,[0,1,2,3,4,5,6,7]]\n",
    "#df_p[9]= pd.to_datetime(df_p[9]).dt.strftime('%d-%m-%Y %H:%M:%S')\n",
    "df_p = df_p.astype({6:int})\n",
    "#print(df_p)\n",
    "#df_p.dtypes\n",
    "\n",
    "#q='CREATE TABLE XTEMP_CANCELLED_LINES_ (HEADER_ID VARCHAR2(100),ORDER_NO VARCHAR2(100),LINE_NO VARCHAR2(100), USER_CODE VARCHAR2(100), SKU VARCHAR2(100), UPC VARCHAR2(100), TDEPT VARCHAR2(100), ORDER_QTY int, CANCEL_QTY int, CANCELED_AT date, CANCEL_TYPE VARCHAR2(100))'\n",
    "#cursor.execute(q)\n",
    "#con.commit()\n",
    "\n",
    "print(\"Pandas dataframe created!!!\")"
   ]
  },
  {
   "cell_type": "markdown",
   "id": "483d66e1",
   "metadata": {},
   "source": [
    "INSERT DATAFRAME INTO ORACLE DB TABLE"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "id": "0218a747",
   "metadata": {},
   "outputs": [],
   "source": [
    "print('Inserting data into table....')\n",
    "\n",
    "data=[]\n",
    "batch_size= 31516.75 \n",
    "\n",
    "for i,line in df_p.iterrows():\n",
    "    sql=\"insert into xtemp_stock_despatch (ID,ITEM_ID,SKU,ORDER_NO,PHYSICAL_STOCK_ID,ROUTING_BARCODE,QTY,SHIPMENT_ID) values (:0,:1,:2,:3,:4,:5,:6,:7)\"\n",
    "    data.append((line[0],line[1],line[2],line[3],line[4],line[5],line[6],line[7]))\n",
    "    if len(data) % batch_size == 0:\n",
    "        cursor.executemany(sql, data)\n",
    "        data = []        \n",
    "    \n",
    "        # the connection is not autocommitted by default, so we must commit to save our changes\n",
    "        \n",
    "#     if data:\n",
    "#         cursor.executemany(sql, data)\n",
    "        con.commit()\n",
    "        conn.commit()\n",
    "\n",
    "print('data loaded into the table successfully!!!') "
   ]
  }
 ],
 "metadata": {
  "kernelspec": {
   "display_name": "Python 3 (ipykernel)",
   "language": "python",
   "name": "python3"
  },
  "language_info": {
   "codemirror_mode": {
    "name": "ipython",
    "version": 3
   },
   "file_extension": ".py",
   "mimetype": "text/x-python",
   "name": "python",
   "nbconvert_exporter": "python",
   "pygments_lexer": "ipython3",
   "version": "3.10.7"
  }
 },
 "nbformat": 4,
 "nbformat_minor": 5
}
