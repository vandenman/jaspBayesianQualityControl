// Copyright (C) 2013-2018 University of Amsterdam
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
// You should have received a copy of the GNU Affero General Public
// License along with this program.  If not, see
// <http://www.gnu.org/licenses/>.
//

import QtQuick
import QtQuick.Layouts
import JASP.Controls

import "./common" as Common

Form
{
	columns:	 2

	VariablesForm
	{
		id:									variablesFormLongFormat

		AvailableVariablesList
		{
			name:							"variablesFormLongFormat"
		}

		AssignedVariablesList
		{
			name:							"measurementLongFormat"
			title:							qsTr("Measurement")
			id:								measurementLongFormat
			allowedColumns:					["scale"]
			singleVariable:					true
		}

	}


	// Section
	// {
	// 	title: qsTr("Process capability options")

		Group
		{
			title:					qsTr("Type of data distribution")


			RadioButtonGroup
			{
				name: 					"capabilityStudyType"
				id: 					capabilityStudyType

				RadioButton
				{
					name: 				"normalCapabilityAnalysis"
					id : 				normalCapabilityAnalysis
					label: 				qsTr("Normal distribution")
					checked: 			true
				}

				RadioButton
				{
					name: 				"tCapabilityAnalysis"
					id : 				tCapabilityAnalysis
					label: 				qsTr("Student's t-distribution")
					// checked: 			true
				}

			}
		}

		Group
		{
			columns: 2
			title: qsTr("Metrics")
			info: qsTr("Select the process capability metrics to report.")
			CheckBox { name: "Cp";   label: qsTr("Cp");  checked: true }
			CheckBox { name: "Cpu";	 label: qsTr("Cpu"); checked: true }
			CheckBox { name: "Cpl";	 label: qsTr("Cpl"); checked: true }
			CheckBox { name: "Cpk";	 label: qsTr("Cpk"); checked: true }
			CheckBox { name: "Cpc";	 label: qsTr("Cpc"); checked: true }
			CheckBox { name: "Cpm";	 label: qsTr("Cpm"); checked: true }
		}

		Group
		{
			title: 							qsTr("Capability Study")

			CheckBox
			{
				name: 						"lowerSpecificationLimit"
				label: 						qsTr("Lower specification limit")
				id:							lowerSpecificationLimit
				childrenOnSameRow:			true
				enableChildrenOnChecked:	false

				DoubleField
				{
					name: 					"lowerSpecificationLimitValue"
					id:						lowerSpecificationLimitValue
					negativeValues:			true
					defaultValue:			-1
					decimals:				9
				}

			}

			CheckBox
			{
				name: 						"target"
				label: 						qsTr("Target value")
				id:							target
				childrenOnSameRow:			true
				enableChildrenOnChecked:	false

				DoubleField
				{
					name: 					"targetValue"
					id:						targetValue
					negativeValues:			true
					defaultValue:			0
					decimals:				9
				}
			}

			CheckBox
			{
				name: 						"upperSpecificationLimit"
				label: 						qsTr("Upper specification limit")
				id:							upperSpecificationLimit
				childrenOnSameRow:			true
				enableChildrenOnChecked:	false

				DoubleField
				{
					name: 					"upperSpecificationLimitValue"
					id:						upperSpecificationLimitValue
					negativeValues:			true
					defaultValue:			1
					decimals:				9
				}

			}

			CheckBox
			{
				name: "timeSeriesPlot"
				label: qsTr("Time series plot")
				checked: false
			}
		}

		Group
		{
			title: qsTr("Process Criteria")
			Layout.columnSpan: 2
			Layout.fillWidth: true
			preferredWidth: form.availableWidth

			ComponentsList
			{
				name: "processCriteria"
				id: processCriteria

				preferredWidth: form.availableWidth - jaspTheme.groupContentPadding

				optionKey: "upper"
				optionKeyLabel: "label"

				addItemManually: true
				minimumItems: 2

				defaultValues:
				[
					{ lower: -Infinity, label: qsTr("Incapable"),    upper: 1.00 },
					{ lower: 1.00,      label: qsTr("Capable"),      upper: 1.33 },
					{ lower: 1.33,      label: qsTr("Satisfactory"), upper: 1.50 },
					{ lower: 1.50,      label: qsTr("Excellent"),    upper: 2.00 },
					{ lower: 2.00,      label: qsTr("Super"),        upper: Infinity }
				]

				headerLabels:
				[
					{
						lower: qsTr("Left bound"),
						label: qsTr("Classification"),
						upper: qsTr("Right bound")
					}
				]
				property int rowRevision: 0
				property int previousCount: 0
				property int thresholdRevision: 0

				function refreshThresholds()
				{
					var oldIndex = processOverviewThreshold.currentIndex

					thresholdRevision++

					Qt.callLater(function() {
						var newCount = overviewThresholdValues().length

						if (newCount === 0)
							return

						processOverviewThreshold.currentIndex =
							Math.min(oldIndex, newCount - 1)
					})
				}

				function initializeNewLastRow()
				{
					if (count < 2)
						return

					var largest = -Infinity

					for (var i = 0; i < count; ++i)
					{
						var row = rowAt(i)

						if (!row)
							continue

						var lower = Number(row.lowerValue)
						var upper = Number(row.upperValue)

						if (isFinite(lower) && lower > largest)
							largest = lower

						if (isFinite(upper) && upper > largest)
							largest = upper
					}

					if (!isFinite(largest))
						largest = 0

					var newBoundary = largest + 1

					var previousLast = rowAt(count - 2)
					var newLast      = rowAt(count - 1)

					if (!previousLast || !newLast)
						return

					// the old last row gets a finite upper bound and the new last row stays open-ended
					previousLast.upperValue = newBoundary
					newLast.lowerValue      = newBoundary
					newLast.upperValue      = Infinity
					refreshThresholds()
					validateCriteria()
				}

				onCountChanged:
				{
					var oldCount = previousCount
					previousCount = count

					if (oldCount > 0 && count > oldCount)
					{
						Qt.callLater(function() {
							processCriteria.initializeNewLastRow()
							processCriteria.refreshRowPositions()
						})
					}
					else
					{
						Qt.callLater(processCriteria.refreshRowPositions)
					}
				}

				Component.onCompleted:
				{
					previousCount = count

					Qt.callLater(function() {
						processCriteria.refreshRowPositions()
						processCriteria.sortAndSynchronize()
					})
				}

				function refreshRowPositions()
				{
					rowRevision++
				}

				function rowIndexOf(row)
				{
					for (var i = 0; i < count; ++i)
					{
						if (rowAt(i) === row)
							return i
					}

					return -1
				}

				function rowsInOrder()
				{
					var rows = []

					for (var i = 0; i < count; ++i)
					{
						var row = rowAt(i)

						if (row)
							rows.push(row)
					}

					return rows
				}

				function overviewThresholdValues()
				{
					var thresholds = []

					for (var i = 0; i < count - 1; ++i)
					{
						var criterion = rowAt(i)

						if (!criterion)
							continue

						var value = Number(criterion.upperValue)

						if (isFinite(value))
							thresholds.push(value)
					}

					return thresholds.map(function(value) {
						return {
							label: String(value),
							value: String(value)
						}
					})
				}

				// Interior boundaries are kept sorted and shared between neighbouring rows. The
				// outer bounds are always open-ended, also after the first or last row is deleted.
				function applyBoundaries(rows, values)
				{
					rows[0].lowerValue = -Infinity

					for (var j = 0; j < values.length; ++j)
					{
						rows[j].upperValue = values[j]
						rows[j + 1].lowerValue = values[j]
					}

					rows[rows.length - 1].upperValue = Infinity

					refreshThresholds()
					validateCriteria()
				}

				function boundaryEdited(boundaryIndex, newValue)
				{
					var rows = rowsInOrder()

					if (rows.length < 2)
						return

					if (boundaryIndex < 0 || boundaryIndex >= rows.length - 1)
						return

					var values = []

					for (var i = 0; i < rows.length - 1; ++i)
					{
						if (i === boundaryIndex)
							values.push(newValue)
						else
							values.push(rows[i].upperValue)
					}

					values.sort(function(a, b) {
						return a - b
					})

					applyBoundaries(rows, values)
				}

				function sortAndSynchronize()
				{
					var rows = rowsInOrder()

					if (rows.length < 2)
						return

					var values = []

					for (var i = 0; i < rows.length - 1; ++i)
						values.push(rows[i].upperValue)

					values.sort(function(a, b) {
						return a - b
					})

					applyBoundaries(rows, values)
				}

				// Equal boundaries and empty labels are rejected here; a control error prevents
				// the analysis from running until the criteria are valid again.
				function validateCriteria()
				{
					var rows = rowsInOrder()

					for (var i = 0; i < rows.length; ++i)
					{
						var boundaryError = ""
						if (i < rows.length - 2 && !(Number(rows[i].upperValue) < Number(rows[i + 1].upperValue)))
							boundaryError = qsTr("Each boundary must be larger than the previous one.")

						var labelError = ""
						if (String(rows[i].labelValue).trim() === "")
							labelError = qsTr("Each region needs a classification label.")

						rows[i].showErrors(boundaryError, labelError)
					}
				}

				rowComponent: Row
				{
					id: criterionRow

					property alias lowerValue: lowerBound.value
					property alias upperValue: upperBound.value
					property alias labelValue: labelField.value

					property bool isFirstRow:
					{
						var revision = processCriteria.rowRevision
						return rowIndex === 0
					}

					property bool isLastRow:
					{
						var revision = processCriteria.rowRevision

						if (processCriteria.count <= 0)
							return false

						return processCriteria.rowAt(processCriteria.count - 1) === criterionRow
					}

					function showErrors(boundaryError, labelError)
					{
						if (boundaryError !== "")
							upperBound.addControlErrorPermanent(boundaryError)
						else
							upperBound.clearControlError()

						if (labelError !== "")
							labelField.addControlErrorPermanent(labelError)
						else
							labelField.clearControlError()
					}

					// Left bound, kept in the layout for the first row (so the header stays aligned) but hidden
					DoubleField
					{
						id: lowerBound
						name: "lower"

						opacity: criterionRow.isFirstRow ? 0 : 1
						enabled: !criterionRow.isFirstRow

						defaultValue: 0
						negativeValues: true
						decimals: 9
						fieldWidth: 80

						onEditingFinished:
						{
							var index =
								processCriteria.rowIndexOf(criterionRow)

							processCriteria.boundaryEdited(
								index - 1,
								Number(displayValue)
							)
						}
					}

					Label
					{
						text: criterionRow.isFirstRow ? "" : "<"
						width: 10
					}

					TextField
					{
						id: labelField
						name: "label"
						startValue: qsTr("Region %1").arg(rowIndex + 1)
						fieldWidth: 120
						onEditingFinished: processCriteria.validateCriteria()
					}

					Label
					{
						text: criterionRow.isLastRow ? "" : "≤"
						width: 10
					}

					// Right bound, hidden for the last row
					DoubleField
					{
						id: upperBound
						name: "upper"

						opacity: criterionRow.isLastRow ? 0 : 1
						enabled: !criterionRow.isLastRow

						defaultValue: 1
						negativeValues: true
						decimals: 9
						fieldWidth: 80

						onEditingFinished:
						{
							var index =
								processCriteria.rowIndexOf(criterionRow)

							processCriteria.boundaryEdited(
								index,
								Number(displayValue)
							)
						}
					}

					Component.onCompleted:
					{
						Qt.callLater(function() {
							processCriteria.refreshRowPositions()
							processCriteria.sortAndSynchronize()
						})
					}

					Component.onDestruction:
					{
						Qt.callLater(function() {
							processCriteria.refreshRowPositions()
							processCriteria.sortAndSynchronize()
						})
					}
				}
			}

			CheckBox
			{
				name: "processOverview"
				id: processOverview
				label: qsTr("Process overview")
				info: qsTr("Show a four-panel overview of the process.")

				DropDown
				{
					name: "processOverviewMetric"
					label: qsTr("Capability metric")
					values:
					[
						{ label: "Cp",  value: "Cp"  },
						{ label: "Cpu", value: "Cpu" },
						{ label: "Cpl", value: "Cpl" },
						{ label: "Cpk", value: "Cpk" },
						{ label: "Cpc", value: "Cpc" },
						{ label: "Cpm", value: "Cpm" }
					]
					indexDefaultValue: 3
				}

				DropDown
				{
					name: "processOverviewThreshold"
					id: processOverviewThreshold
					label: qsTr("Threshold")
					indexDefaultValue: 1

					values:
					{
						var revision = processCriteria.thresholdRevision
						return processCriteria.overviewThresholdValues()
					}
				}

				DropDown
				{
					name: "processOverviewReferencePrior"
					label: qsTr("Reference prior")
					info: qsTr("Prior used for the sensitivity analysis. The DCSI and unit information priors are only available for the normal distribution.")
					// qc supports the DCSI and unit information priors only for the normal distribution
					values: capabilityStudyType.value === "normalCapabilityAnalysis"
						? [
							{ label: qsTr("DCSI"),             value: "DCSI" },
							{ label: qsTr("Jeffreys"),         value: "Jeffreys" },
							{ label: qsTr("Unit information"), value: "unit_information" }
						]
						: [
							{ label: qsTr("Jeffreys"),         value: "Jeffreys" }
						]
					indexDefaultValue: 0
				}

				RadioButtonGroup
				{
					name: "processOverviewBinning"
					title: qsTr("Sequential updates")
					info: qsTr("Each update refits the model to all observations up to that point. The first update always uses the first 3 observations and the last update uses all observations.")

					RadioButton
					{
						value: "noBins"
						label: qsTr("No. bins")
						checked: true
						childrenOnSameRow: true
						IntegerField
						{
							name: "processOverviewNumberOfBins"
							defaultValue: 5
							min: 1
						}
					}

					RadioButton
					{
						value: "observationsPerBin"
						label: qsTr("No. observations per bin")
						info: qsTr("Number of observations added between consecutive updates, starting after the first 3 observations.")
						childrenOnSameRow: true
						IntegerField
						{
							name: "processOverviewObservationsPerBin"
							defaultValue: 10
							min: 1
						}
					}

					RadioButton
					{
						value: "perObservation"
						label: qsTr("Per observation")
					}
				}
			}
		}

		// }



	Section
	{
		title: qsTr("Tables")
		CheckBox
		{
			name: "intervalTable"
			label: qsTr("Interval table")
			info: qsTr("Show posterior probabilities for the process criteria defined above.")
		}
		CIField
		{
			name: "credibleIntervalWidth"
			label: qsTr("Credible interval")
			info: qsTr("Width of the credible interval used for the posterior distribution in the Capability table.")
		}
	}

	Section
	{

		title: qsTr("Prior and Posterior Inference")

		Common.PlotLayout {}

		Common.PlotLayout
		{
			baseName: "priorDistributionPlot"
			baseLabel: qsTr("Prior distribution")
			hasPrior: false
		}

	}

	Section
	{
		title: qsTr("Sequential Analysis")

		Common.PlotLayout
		{
			id: sequentialAnalysisPointEstimatePlot
			baseName: "sequentialAnalysisPointEstimatePlot"
			baseLabel: qsTr("Point estimate plot")
			hasPrior: false
		}

		Common.PlotLayout
		{
			id: sequentialAnalysisIntervalEstimatePlot
			baseName: "sequentialAnalysisPointIntervalPlot"
			baseLabel: qsTr("Interval estimate plot")
			hasPrior: false
			hasEstimate: false
			hasCi: false
			hasType: true
		}

		Group
		{
			CheckBox
			{
				enabled:	sequentialAnalysisPointEstimatePlot.checked || sequentialAnalysisIntervalEstimatePlot.checked
				id:			sequentialAnalysisAdditionalInfo
				name:		"sequentialAnalysisPlotAdditionalInfo"
				label:		qsTr("Show process criteria")
				checked:	true
				info:		qsTr("Add a secondary right axis with condition bounds for the process")
			}

			CheckBox
			{
				// TODO:
				enabled:	sequentialAnalysisPointEstimatePlot.checked || sequentialAnalysisIntervalEstimatePlot.checked
				name:		"sequentialAnalysisUpdatingTable"
				label:		qsTr("Posterior updating table")
				checked:	false
				info:		qsTr("Show the data from the sequential analysis in a table. Will show both the information for the point estimate and interval estimate plots, if both are selected.")
			}
		}
	}

	Section
	{

		title: qsTr("Prior and Posterior Predictive Plots")

		Common.PlotLayout
		{
			baseName: "posteriorPredictiveDistributionPlot"
			baseLabel: qsTr("Posterior predictive distribution")
			hasPrior: false
			hasAxes: false
			hasPanels: false
		}

		Common.PlotLayout
		{
			baseName: "priorPredictiveDistributionPlot"
			baseLabel: qsTr("Prior predictive distribution")
			hasPrior: false
			hasAxes: false
			hasPanels: false
		}

	}


	Section
	{
		title: qsTr("Prior Distributions")

		// TODO: this dropdown should just show the same GUI as the custom one
		// but disable e.g., the DropDown itself and instead show the prior
		// also disable all truncation for non-custom ones
		// NOTE: the above is done, but default values cannot be set yet.

		DropDown
		{
			id: priorSettings
			name: "priorSettings"
			label: qsTr("Prior distributions")
			values:
			[
				{label: qsTr("Default"),					value: "default"},
				{label: qsTr("Informed conjugate"),			value: "conjugate"},
				// {label: qsTr("Informed conjugate"),			value: "weaklyInformativeConjugate"},
				{label: qsTr("Informed uniform"),			value: "weaklyInformativeUniform"},
				{label: qsTr("Custom informative"),			value: "customInformative"},
			]
		}

		Common.Priors
		{

			// visible: priorSettings.currentValue === "customInformative"
			priorType: capabilityStudyType.value === "normalCapabilityAnalysis" ? "normalModel" : "tModel"

			hasTruncation: priorSettings.currentValue === "customInformative"
			hasParameters: priorSettings.currentValue !== "default"
			visible:       priorSettings.currentValue !== "default"

			dropDownValuesMap: {
				switch (priorSettings.currentValue) {
					case "default":
						return {
							"mean": 	[{ label: qsTr("Jeffreys"),				value: "jeffreys"}],
							"sigma": 	[{ label: qsTr("Jeffreys"),				value: "jeffreys"}],
							"df": 		[{ label: qsTr("Gamma(α,β)"),			value: "gammaAB" }]
						}
					case "conjugate":
						return {
							"mean": 	[{ label: qsTr("Normal(μ,σ)"),			value: "normal"}],
							"sigma": 	[{ label: qsTr("Gamma(α,β)"),			value: "gammaAB" }],
							"df": 		[{ label: qsTr("Gamma(α,β)"),			value: "gammaAB" }]
						};
					// case "weaklyInformativeConjugate":
					// 	return {
					// 		"mean": 	[{ label: qsTr("Normal(μ,σ)"),			value: "normal"}],
					// 		"sigma": 	[{ label: qsTr("Gamma(α,β)"),			value: "gammaAB" }],
					// 		"df": 		[{ label: qsTr("Gamma(α,β)"),			value: "gammaAB" }]
					// 	}
					case "weaklyInformativeUniform":
						return {
							"mean": 	[{ label: qsTr("Uniform(a,b)"),			value: "uniform"}],
							"sigma": 	[{ label: qsTr("Uniform(a,b)"),			value: "uniform"}],
							"df": 		[{ label: qsTr("Gamma(α,β)"),			value: "gammaAB" }]
						}
					case "customInformative":
						return undefined;
				}
			}
		}
	}

	Section
	{
		title: qsTr("Advanced Options")

		Group
		{
			title: qsTr("MCMC Settings")
			info: qsTr("Adjust the Markov Chain Monte Carlo (MCMC) settings for estimating the posterior distribution.")
			IntegerField
			{
				name: "noIterations"
				label: qsTr("No. iterations")
				defaultValue: 5000
				min: 100
				max: 100000000
				info: qsTr("Number of MCMC iterations used for estimating the posterior distribution.")
			}
			IntegerField
			{
				name: "noWarmup"
				label: qsTr("No. warmup samples")
				defaultValue: 1000
				min: 0
				max: 100000000
				info: qsTr("Number of initial MCMC samples to discard.")
			}
			IntegerField
			{
				name: "noChains"
				label: qsTr("No. chains")
				defaultValue: 1
				min: 1
				max: 128
				info: qsTr("Number of MCMC chains to run.")
			}
		}
	}
}
