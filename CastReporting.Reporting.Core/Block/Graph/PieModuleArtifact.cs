﻿
/*
 *   Copyright (c) 2019 CAST
 *
 * Licensed under a custom license, Version 1.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License, accessible in the main project
 * source code: Empowerment.
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */
using System;
using System.Collections.Generic;
using CastReporting.Reporting.Atrributes;
using CastReporting.Reporting.Builder.BlockProcessing;
using CastReporting.Reporting.ReportingModel;
using CastReporting.Reporting.Core.Languages;
using CastReporting.BLL.Computing;
using CastReporting.Domain;



namespace CastReporting.Reporting.Block.Graph 
{
    [Block("MODULES_ARTIFACTS")]
    public class PieModuleArtifact : GraphBlock
    {


        #region METHODS

        public override TableDefinition Content(ReportData reportData, Dictionary<string, string> options)
        {

            int nbResult = reportData.Parameter.NbResultDefault, tmpNb;
            if (null != options && options.ContainsKey("COUNT") && int.TryParse(options["COUNT"], out tmpNb) && tmpNb > 0)
            {
                nbResult = tmpNb;
            }


            if (reportData.CurrentSnapshot == null) return null;
            var moduleArtifacts = MeasureUtility.GetModulesMeasure(reportData.CurrentSnapshot, nbResult, Constants.SizingInformations.ArtifactNumber);

            List<string> rowData = new List<string>();
            rowData.AddRange(new[] { Labels.Name, Labels.Artifacts });
          
            foreach (var mod in moduleArtifacts)
            {
                rowData.Add(mod.Name);
                rowData.Add(Convert.ToInt32(mod.Value).ToString());
            }
              

            TableDefinition resultTable = new TableDefinition
            {
                HasRowHeaders = true,
                HasColumnHeaders = false,
                NbRows = moduleArtifacts.Count + 1,
                NbColumns = 2,
                Data = rowData
            };

            return resultTable;
        }

        
        #endregion METHODS
    }

}