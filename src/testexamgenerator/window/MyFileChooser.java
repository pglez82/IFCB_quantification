/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package testexamgenerator.window;

import java.io.File;
import javax.swing.JFileChooser;
import javax.swing.filechooser.FileFilter;

/**
 *
 * @author pablo
 */
public class MyFileChooser extends JFileChooser {
    public MyFileChooser()
    {
        super(new File("."));
        setFileFilter(new FileFilter() {

            @Override
            public boolean accept(File file) {
                return !file.isFile() || file.getName().endsWith(".xml");
            }

            @Override
            public String getDescription() {
                return "*.xml Test Exam files";
            }
        });
    }
}
