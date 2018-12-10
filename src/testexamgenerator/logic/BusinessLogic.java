/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package testexamgenerator.logic;

import com.hp.hpl.jena.util.FileUtils;
import java.io.File;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;
import javax.xml.bind.JAXBContext;
import javax.xml.bind.JAXBException;
import javax.xml.bind.Marshaller;
import javax.xml.bind.Unmarshaller;
import net.sf.jasperreports.engine.JRDataSource;
import net.sf.jasperreports.engine.JRException;
import net.sf.jasperreports.engine.JasperCompileManager;
import net.sf.jasperreports.engine.JasperExportManager;
import net.sf.jasperreports.engine.JasperFillManager;
import net.sf.jasperreports.engine.JasperPrint;
import net.sf.jasperreports.engine.data.JRBeanCollectionDataSource;
import testexamgenerator.dto.Question;
import testexamgenerator.dto.Subject;
import testexamgenerator.dto.Unit;
import testexamgenerator.logic.exception.NotEnoughQuestionsException;

/**
 *
 * @author pablo
 */
public class BusinessLogic {

    private static List<Unit> listUnits = new ArrayList<>();
    private static final String TEMPLATES_DIR = "templates";
    private static final String EXAMS_DIR = "exams";
    private static File currentFile;

    public static boolean saveToDiskAs(File fileName) {

        try {

            JAXBContext jaxbContext = JAXBContext.newInstance(Subject.class);
            Marshaller jaxbMarshaller = jaxbContext.createMarshaller();

            // output pretty printed
            jaxbMarshaller.setProperty(Marshaller.JAXB_FORMATTED_OUTPUT, true);

            jaxbMarshaller.marshal(new Subject(listUnits), fileName);
            currentFile = fileName;
            return true;

        } catch (JAXBException e) {
            return false;
        }

    }

    public static String getCurrentFileName() {
        if (currentFile != null) {
            return currentFile.getName();
        } else {
            return "";
        }
    }

    public static boolean saveToDisk() {
        if (currentFile != null) {
            saveToDiskAs(currentFile);
            return true;
        } else {
            return false;
        }
    }

    public static boolean loadFromDisk(File fileName) {

        try {

            JAXBContext jaxbContext = JAXBContext.newInstance(Subject.class);

            Unmarshaller jaxbUnmarshaller = jaxbContext.createUnmarshaller();
            Subject subject = (Subject) jaxbUnmarshaller.unmarshal(fileName);
            listUnits = subject.getListUnits();
            currentFile = fileName;
            return true;

        } catch (JAXBException e) {
            return false;
        }

    }

    /**
     *
     * @param questionNumber number of quetions
     * @param listUnits only questions of this units are generated
     * @return
     */
    private static List<Question> generateExam(int questionNumber, int[] listUnitsExam,boolean theoryQuestions,boolean practicalQuestions) throws NotEnoughQuestionsException {
        int questionsByUnit = questionNumber / listUnitsExam.length;
        int mod = questionNumber % listUnitsExam.length;
        List<Question> questionList = new ArrayList<>();
        for (int unitIndex : listUnitsExam) {
            Unit unit = listUnits.get(unitIndex);
            int extra = 0;
            if (mod>0) //Manage situation when division is not an int
            {
                extra=1;
                mod--;
            }
            questionList.addAll(unit.getRandomQuestions(questionsByUnit+extra,theoryQuestions,practicalQuestions));
        }
        return questionList;
    }

    public static boolean generateExamenToPdf(int questionNumber, int[] listUnitsExam, String fileName, String template, String subtitle,boolean theoryQuestions,boolean practicalQuestions) throws NotEnoughQuestionsException {
        try {
            String ext = FileUtils.getFilenameExt(fileName);
            String dirName = fileName;
            if ("".equals(ext)) {
                fileName = fileName + ".pdf";
            }
            File directorio = new File(EXAMS_DIR + File.separator + dirName);
            if (!directorio.exists()) {
                directorio.mkdir();
            }
            List<Question> listQuestions = generateExam(questionNumber, listUnitsExam,theoryQuestions,practicalQuestions);
            JRDataSource dataSource = new JRBeanCollectionDataSource(listQuestions);
            JasperCompileManager.compileReportToFile(TEMPLATES_DIR + File.separator + template, "temp.jasper");
            JasperCompileManager.compileReportToFile(TEMPLATES_DIR + File.separator + "answer_subreport.jrxml", "answer_subreport.jasper");
            Map params = new HashMap<>();
            params.put("NOTAEXAMEN", subtitle);
            params.put("SOLUTION", false);
            JasperPrint print = JasperFillManager.fillReport("temp.jasper", params, dataSource);
            JasperExportManager.exportReportToPdfFile(print, EXAMS_DIR + File.separator + dirName + File.separator + fileName);
            //Solution
            JRDataSource dataSource2 = new JRBeanCollectionDataSource(listQuestions);
            Map params2 = new HashMap<>();
            params2.put("NOTAEXAMEN", subtitle);
            params2.put("SOLUTION", true);
            JasperPrint print2 = JasperFillManager.fillReport("temp.jasper", params2, dataSource2);
            JasperExportManager.exportReportToPdfFile(print2, EXAMS_DIR + File.separator + dirName + File.separator + "solution_" + fileName);
            File file = new File("temp.jasper");
            file.delete();
            File file2 = new File("answer_subreport.jasper");
            file2.delete();
            MCTestGenerator.generateMCTest(listQuestions, EXAMS_DIR + File.separator + dirName);
        } catch (JRException ex) {
            return false;
        } 
        return true;
        
    }

    public static boolean addUnit(String unitString) {
        Unit unit = new Unit(unitString);
        if (!listUnits.contains(unit)) {
            listUnits.add(unit);
            saveToDisk();
            return true;
        } else {
            return false;
        }
    }

    public static List<Unit> getUnitList() {
        return new ArrayList(listUnits);
    }

}
