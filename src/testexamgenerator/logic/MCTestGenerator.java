/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package testexamgenerator.logic;

import java.io.File;
import java.util.List;
import org.odftoolkit.odfdom.type.Color;
import org.odftoolkit.simple.TextDocument;
import org.odftoolkit.simple.style.Border;
import org.odftoolkit.simple.style.StyleTypeDefinitions;
import org.odftoolkit.simple.table.Cell;
import org.odftoolkit.simple.table.Table;
import testexamgenerator.dto.Question;

/**
 *
 * @author pablo
 */
public class MCTestGenerator 
{
    private static final int QUESTION_PER_TABLE = 30;
    
    public static void generateMCTest(List<Question> listQuestions,String dirName) throws Exception
    {
        int numTables;
        if (listQuestions.size()>QUESTION_PER_TABLE)
        {
            numTables = listQuestions.size()/QUESTION_PER_TABLE;
            if ((listQuestions.size()%QUESTION_PER_TABLE)!=0)
                numTables++;
        }
        else
            numTables=1;
        
        int questionsPerTable = listQuestions.size()/numTables;
        int firstTableExtra = listQuestions.size()%numTables;
        
        TextDocument outputOdt;
        outputOdt = TextDocument.newTextDocument(TextDocument.OdfMediaType.TEXT);
        
        for (int i=0;i<numTables;i++)
        {
            if (i==0)
                createTable(outputOdt, listQuestions, 0,questionsPerTable+firstTableExtra-1);
            else
                createTable(outputOdt, listQuestions, (i*questionsPerTable)+firstTableExtra,((i+1)*questionsPerTable)+firstTableExtra-1);
            outputOdt.addParagraph("");
            outputOdt.addParagraph("");
        
        }
        outputOdt.save(dirName+File.separator+"plantillamctest.odt");
    }
    
    
    private static void createTable(TextDocument outputOdt,List<Question> listQuestions,int from, int to)
    {
        int nquestions = to-from+1;
        
        Table table = outputOdt.addTable(6,nquestions+2);
        
        int indice=1;
        for (int i = from+1; i<=to+1; i++)
        {
            Cell cell = table.getCellByPosition(indice,0);
            cell.setStringValue(Integer.toString(i));
            indice++;
        }
        
        table.getCellByPosition(0,1).setStringValue("A");
        table.getCellByPosition(0,2).setStringValue("B");
        table.getCellByPosition(0,3).setStringValue("C");
        table.getCellByPosition(0,4).setStringValue("D");
        
        //Ponmeos las celdas negras de las esquinas
        table.getCellByPosition(0,0).setCellBackgroundColor(Color.BLACK);
        table.getCellByPosition(nquestions+1,0).setCellBackgroundColor(Color.BLACK);
        table.getCellByPosition(0,5).setCellBackgroundColor(Color.BLACK);
        table.getCellByPosition(nquestions+1,5).setCellBackgroundColor(Color.BLACK);
        
        //Quiamos los bordes innecesarios
        for (int i = 0; i<nquestions+2;i++)
        {
            table.getCellByPosition(0,1).setBorders(StyleTypeDefinitions.CellBordersType.LEFT_RIGHT, Border.NONE);
            table.getCellByPosition(i,0).setBorders(StyleTypeDefinitions.CellBordersType.TOP, Border.NONE);
            table.getCellByPosition(i,5).setBorders(StyleTypeDefinitions.CellBordersType.LEFT_RIGHT, Border.NONE);
            table.getCellByPosition(i,5).setBorders(StyleTypeDefinitions.CellBordersType.BOTTOM, Border.NONE);
        }
        for (int i=0;i<6;i++)
        {
            table.getCellByPosition(0,i).setBorders(StyleTypeDefinitions.CellBordersType.LEFT, Border.NONE);
            table.getCellByPosition(0,i).setBorders(StyleTypeDefinitions.CellBordersType.TOP_BOTTOM, Border.NONE);
        }
        
        if (listQuestions!=null)
        {
            indice=0;
            for (int nq=from;nq<to+1;nq++)
            {
                int correcta=0;
                for (int i=0;i<4;i++)
                    if (listQuestions.get(nq).getAnswerList().get(i).isCorrect())
                        correcta = i;
                table.getCellByPosition(indice+1, correcta+1).setCellBackgroundColor(Color.BLACK);
                indice++;
            }
        }
       
        
        
    }
}
